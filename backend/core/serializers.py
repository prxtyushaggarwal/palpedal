from decimal import Decimal
from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Wallet, WalletTransaction, Station, Cycle, RideBooking

class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'password', 'first_name', 'last_name']

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )
        # Create empty wallet with initial welcome bonus or $0.00
        Wallet.objects.create(user=user, balance=Decimal('0.00'))
        return user

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']

class WalletTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = WalletTransaction
        fields = ['id', 'transaction_type', 'amount', 'description', 'ride', 'created_at']

class WalletSerializer(serializers.ModelSerializer):
    transactions = WalletTransactionSerializer(many=True, read_only=True)
    username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = Wallet
        fields = ['id', 'username', 'balance', 'updated_at', 'transactions']

class WalletTopUpSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal('1.00'))
    payment_method = serializers.CharField(default='Simulated Card / UPI')

class CycleSerializer(serializers.ModelSerializer):
    current_station_name = serializers.CharField(source='current_station.name', read_only=True)

    class Meta:
        model = Cycle
        fields = [
            'id', 'cycle_number', 'qr_code', 'current_station',
            'current_station_name', 'status', 'lock_status',
            'battery_percentage', 'last_latitude', 'last_longitude'
        ]

class StationSerializer(serializers.ModelSerializer):
    available_cycles = serializers.IntegerField(source='available_cycles_count', read_only=True)
    cycles = CycleSerializer(many=True, read_only=True)

    class Meta:
        model = Station
        fields = ['id', 'name', 'latitude', 'longitude', 'address', 'capacity', 'available_cycles', 'cycles']

class RideBookingSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    cycle_number = serializers.CharField(source='cycle.cycle_number', read_only=True)
    start_station_name = serializers.CharField(source='start_station.name', read_only=True)
    end_station_name = serializers.CharField(source='end_station.name', read_only=True)

    class Meta:
        model = RideBooking
        fields = [
            'id', 'username', 'cycle', 'cycle_number', 'start_station',
            'start_station_name', 'end_station', 'end_station_name',
            'start_time', 'end_time', 'duration_minutes', 'total_fare', 'status'
        ]

class StartRideSerializer(serializers.Serializer):
    qr_code = serializers.CharField(required=True)

class EndRideSerializer(serializers.Serializer):
    ride_id = serializers.UUIDField(required=True)
    end_station_id = serializers.UUIDField(required=True)
