from decimal import Decimal
from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework import status
from core.models import Wallet, WalletTransaction, Station, Cycle, RideBooking

class PalPedalTestSuite(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Create Station
        self.station_a = Station.objects.create(
            name='Central Station A',
            latitude=Decimal('28.613900'),
            longitude=Decimal('77.209000'),
            address='Station Road',
            capacity=10
        )
        self.station_b = Station.objects.create(
            name='Campus Station B',
            latitude=Decimal('28.620000'),
            longitude=Decimal('77.215000'),
            address='North Avenue',
            capacity=10
        )

        # Create Cycle
        self.cycle = Cycle.objects.create(
            cycle_number='CYC-TEST-01',
            qr_code='QR-TEST-001',
            current_station=self.station_a,
            status='AVAILABLE',
            lock_status='LOCKED',
            battery_percentage=95
        )

        # Register User
        self.user = User.objects.create_user(
            username='tester',
            email='tester@palpedal.io',
            password='Password123!'
        )
        self.wallet = Wallet.objects.create(user=self.user, balance=Decimal('20.00'))

        # Authenticate
        self.client.force_authenticate(user=self.user)

    def test_user_registration_creates_wallet(self):
        """TC-AUTH-01: Verifies registration auto-provisions a wallet."""
        unauth_client = APIClient()
        response = unauth_client.post('/api/auth/register/', {
            'username': 'newbie',
            'email': 'newbie@palpedal.io',
            'password': 'StrongPassword123'
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        new_user = User.objects.get(username='newbie')
        self.assertTrue(hasattr(new_user, 'wallet'))
        self.assertEqual(new_user.wallet.balance, Decimal('0.00'))

    def test_wallet_topup(self):
        """TC-WLT-01: Verifies wallet top-up increases balance and logs transaction."""
        response = self.client.post('/api/wallet/topup/', {'amount': '15.50'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('35.50'))
        self.assertTrue(WalletTransaction.objects.filter(wallet=self.wallet, transaction_type='CREDIT').exists())

    def test_start_ride_insufficient_balance(self):
        """TC-WLT-02: Prevents starting a ride if wallet has less than $5.00."""
        self.wallet.balance = Decimal('2.00')
        self.wallet.save()

        response = self.client.post('/api/rides/start/', {'qr_code': 'QR-TEST-001'})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Insufficient wallet balance', response.data['error'])

    def test_successful_ride_lifecycle(self):
        """TC-RIDE-01 & TC-RIDE-03: Full lifecycle (start ride -> in use -> end ride -> debit wallet)."""
        # 1. Start ride
        start_res = self.client.post('/api/rides/start/', {'qr_code': 'QR-TEST-001'})
        self.assertEqual(start_res.status_code, status.HTTP_201_CREATED)
        ride_id = start_res.data['ride']['id']

        self.cycle.refresh_from_db()
        self.assertEqual(self.cycle.status, 'IN_USE')
        self.assertEqual(self.cycle.lock_status, 'UNLOCKED')
        self.assertIsNone(self.cycle.current_station)

        # 2. Check active ride endpoint
        active_res = self.client.get('/api/rides/active/')
        self.assertEqual(active_res.status_code, status.HTTP_200_OK)
        self.assertIsNotNone(active_res.data['active_ride'])

        # 3. End ride at Station B
        end_res = self.client.post('/api/rides/end/', {
            'ride_id': ride_id,
            'end_station_id': str(self.station_b.id)
        })
        self.assertEqual(end_res.status_code, status.HTTP_200_OK)

        # Verify cycle state restored
        self.cycle.refresh_from_db()
        self.assertEqual(self.cycle.status, 'AVAILABLE')
        self.assertEqual(self.cycle.lock_status, 'LOCKED')
        self.assertEqual(self.cycle.current_station, self.station_b)

        # Verify wallet balance reduced
        self.wallet.refresh_from_db()
        self.assertLess(self.wallet.balance, Decimal('20.00'))

        # Verify transaction logged
        debit_tx = WalletTransaction.objects.filter(wallet=self.wallet, transaction_type='DEBIT').first()
        self.assertIsNotNone(debit_tx)
        self.assertEqual(str(debit_tx.ride_id), str(ride_id))

    def test_cannot_start_already_in_use_cycle(self):
        """TC-RIDE-02: Cannot unlock a cycle currently in use."""
        self.cycle.status = 'IN_USE'
        self.cycle.save()

        response = self.client.post('/api/rides/start/', {'qr_code': 'QR-TEST-001'})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
