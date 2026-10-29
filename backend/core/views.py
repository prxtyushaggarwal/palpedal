from decimal import Decimal
from django.db import transaction
from django.utils import timezone
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from rest_framework import status, permissions, viewsets
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.authtoken.models import Token

from .models import Wallet, WalletTransaction, Station, Cycle, RideBooking
from .serializers import (
    UserRegistrationSerializer, UserSerializer, WalletSerializer,
    WalletTopUpSerializer, StationSerializer, CycleSerializer,
    RideBookingSerializer, StartRideSerializer, EndRideSerializer
)

MINIMUM_WALLET_BALANCE_TO_START_RIDE = Decimal('5.00')

class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = UserRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            token, _ = Token.objects.get_or_create(user=user)
            return Response({
                'message': 'User registered successfully with initial PalPedal wallet.',
                'token': token.key,
                'user': UserSerializer(user).data
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        user = authenticate(username=username, password=password)
        if not user:
            return Response({'error': 'Invalid username or password'}, status=status.HTTP_401_UNAUTHORIZED)
        token, _ = Token.objects.get_or_create(user=user)
        # Ensure wallet exists
        Wallet.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user': UserSerializer(user).data
        }, status=status.HTTP_200_OK)

class ProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

class StationViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.AllowAny]
    queryset = Station.objects.filter(is_active=True).prefetch_related('cycles')
    serializer_class = StationSerializer

class CycleViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.AllowAny]
    queryset = Cycle.objects.all().select_related('current_station')
    serializer_class = CycleSerializer

class WalletDetailView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        wallet, _ = Wallet.objects.get_or_create(user=request.user)
        return Response(WalletSerializer(wallet).data)

class WalletTopUpView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = WalletTopUpSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        amount = serializer.validated_data['amount']
        method = serializer.validated_data.get('payment_method', 'Simulated Card')

        with transaction.atomic():
            wallet, _ = Wallet.objects.select_for_update().get_or_create(user=request.user)
            wallet.balance += amount
            wallet.save()

            WalletTransaction.objects.create(
                wallet=wallet,
                transaction_type='CREDIT',
                amount=amount,
                description=f'Wallet Recharge via {method}'
            )

        return Response({
            'message': f'Successfully added ${amount:.2f} to PalPedal wallet.',
            'new_balance': str(wallet.balance)
        }, status=status.HTTP_200_OK)

class StartRideView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = StartRideSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        qr_code = serializer.validated_data['qr_code']

        with transaction.atomic():
            # Check user has no ongoing active rides
            active_ride = RideBooking.objects.filter(user=request.user, status='ACTIVE').first()
            if active_ride:
                return Response({
                    'error': 'You already have an active ride in progress.',
                    'active_ride_id': str(active_ride.id)
                }, status=status.HTTP_400_BAD_REQUEST)

            # Check wallet balance
            wallet, _ = Wallet.objects.select_for_update().get_or_create(user=request.user)
            if wallet.balance < MINIMUM_WALLET_BALANCE_TO_START_RIDE:
                return Response({
                    'error': f'Insufficient wallet balance (${wallet.balance}). Minimum ${MINIMUM_WALLET_BALANCE_TO_START_RIDE} required to unlock a cycle.',
                    'current_balance': str(wallet.balance)
                }, status=status.HTTP_400_BAD_REQUEST)

            # Find cycle
            try:
                cycle = Cycle.objects.select_for_update().get(qr_code=qr_code)
            except Cycle.DoesNotExist:
                return Response({'error': f'No cycle found with QR code "{qr_code}".'}, status=status.HTTP_404_NOT_FOUND)

            if cycle.status != 'AVAILABLE':
                return Response({'error': f'Cycle {cycle.cycle_number} is currently {cycle.status}. Cannot unlock.'}, status=status.HTTP_400_BAD_REQUEST)

            origin_station = cycle.current_station

            # Unlock cycle
            cycle.status = 'IN_USE'
            cycle.lock_status = 'UNLOCKED'
            cycle.current_station = None
            cycle.save()

            # Create Ride Booking
            ride = RideBooking.objects.create(
                user=request.user,
                cycle=cycle,
                start_station=origin_station,
                start_time=timezone.now(),
                status='ACTIVE'
            )

        return Response({
            'message': f'Cycle {cycle.cycle_number} successfully unlocked! Have a safe ride.',
            'ride': RideBookingSerializer(ride).data
        }, status=status.HTTP_201_CREATED)

class EndRideView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = EndRideSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        ride_id = serializer.validated_data['ride_id']
        end_station_id = serializer.validated_data['end_station_id']

        with transaction.atomic():
            try:
                ride = RideBooking.objects.select_for_update().get(id=ride_id, user=request.user, status='ACTIVE')
            except RideBooking.DoesNotExist:
                return Response({'error': 'Active ride not found or already concluded.'}, status=status.HTTP_404_NOT_FOUND)

            try:
                station = Station.objects.get(id=end_station_id, is_active=True)
            except Station.DoesNotExist:
                return Response({'error': 'Invalid destination docking station.'}, status=status.HTTP_404_NOT_FOUND)

            cycle = Cycle.objects.select_for_update().get(id=ride.cycle.id)

            # Finalize ride calculations
            end_now = timezone.now()
            mins, fare = ride.calculate_fare(end_now)

            ride.end_time = end_now
            ride.duration_minutes = mins
            ride.total_fare = fare
            ride.end_station = station
            ride.status = 'COMPLETED'
            ride.save()

            # Lock cycle back at the station
            cycle.status = 'AVAILABLE'
            cycle.lock_status = 'LOCKED'
            cycle.current_station = station
            cycle.save()

            # Deduct from Wallet atomically
            wallet, _ = Wallet.objects.select_for_update().get_or_create(user=request.user)
            wallet.balance -= fare
            wallet.save()

            # Record Wallet Debit Transaction
            WalletTransaction.objects.create(
                wallet=wallet,
                transaction_type='DEBIT',
                amount=fare,
                description=f'Ride fare ({mins} mins on {cycle.cycle_number})',
                ride=ride
            )

        return Response({
            'message': 'Ride successfully completed. Fare deducted from your PalPedal wallet.',
            'ride': RideBookingSerializer(ride).data,
            'duration_minutes': mins,
            'total_fare': str(fare),
            'remaining_wallet_balance': str(wallet.balance)
        }, status=status.HTTP_200_OK)

class ActiveRideView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        ride = RideBooking.objects.filter(user=request.user, status='ACTIVE').first()
        if not ride:
            return Response({'active_ride': None})

        mins, projected_fare = ride.calculate_fare(timezone.now())
        data = RideBookingSerializer(ride).data
        data['live_duration_minutes'] = mins
        data['live_projected_fare'] = str(projected_fare)
        return Response({'active_ride': data})

class RideHistoryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        rides = RideBooking.objects.filter(user=request.user).order_by('-start_time')
        return Response(RideBookingSerializer(rides, many=True).data)
