from decimal import Decimal
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from core.models import Station, Cycle, Wallet, WalletTransaction

class Command(BaseCommand):
    help = 'Seeds initial stations, cycles, and demo accounts for PalPedal'

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE('Beginning PalPedal data seeding...'))

        # 1. Create or get Demo Rider
        user, created = User.objects.get_or_create(
            username='rider1',
            defaults={
                'email': 'rider1@palpedal.io',
                'first_name': 'Alex',
                'last_name': 'Rider'
            }
        )
        if created:
            user.set_password('palpedal123')
            user.save()
            self.stdout.write(self.style.SUCCESS('Created demo user "rider1" (password: palpedal123)'))

        # Wallet
        wallet, _ = Wallet.objects.get_or_create(user=user)
        wallet.balance = Decimal('35.00')
        wallet.save()
        WalletTransaction.objects.get_or_create(
            wallet=wallet,
            transaction_type='CREDIT',
            amount=Decimal('35.00'),
            description='Initial Promotional Top-up'
        )

        # 2. Seed Stations
        stations_data = [
            {
                'name': 'PalPedal Metro Hub',
                'latitude': Decimal('28.613939'),
                'longitude': Decimal('77.209021'),
                'address': 'Gate 2, Central Metro Interchange',
                'capacity': 20,
            },
            {
                'name': 'University North Campus Station',
                'latitude': Decimal('28.620000'),
                'longitude': Decimal('77.215000'),
                'address': 'Near Main Library & Student Center',
                'capacity': 15,
            },
            {
                'name': 'Tech Park Innovation Dock',
                'latitude': Decimal('28.610000'),
                'longitude': Decimal('77.200000'),
                'address': 'Tower B, Cyber Plaza Entrance',
                'capacity': 25,
            },
            {
                'name': 'Green Riverfront Park Station',
                'latitude': Decimal('28.617500'),
                'longitude': Decimal('77.225000'),
                'address': 'Riverside Promenade Trailhead',
                'capacity': 12,
            },
        ]

        stations = []
        for s_data in stations_data:
            station, _ = Station.objects.get_or_create(
                name=s_data['name'],
                defaults=s_data
            )
            stations.append(station)
            self.stdout.write(f'Station ready: {station.name}')

        # 3. Seed Cycles
        cycles_config = [
            ('CYC-101', 'QR-PAL-101', stations[0], 98),
            ('CYC-102', 'QR-PAL-102', stations[0], 92),
            ('CYC-103', 'QR-PAL-103', stations[0], 85),
            ('CYC-104', 'QR-PAL-104', stations[1], 100),
            ('CYC-105', 'QR-PAL-105', stations[1], 79),
            ('CYC-106', 'QR-PAL-106', stations[1], 90),
            ('CYC-107', 'QR-PAL-107', stations[2], 95),
            ('CYC-108', 'QR-PAL-108', stations[2], 88),
            ('CYC-109', 'QR-PAL-109', stations[2], 64),
            ('CYC-110', 'QR-PAL-110', stations[3], 93),
            ('CYC-111', 'QR-PAL-111', stations[3], 87),
            ('CYC-112', 'QR-PAL-112', stations[3], 100),
        ]

        for cycle_num, qr, stn, battery in cycles_config:
            cycle, _ = Cycle.objects.get_or_create(
                cycle_number=cycle_num,
                defaults={
                    'qr_code': qr,
                    'current_station': stn,
                    'status': 'AVAILABLE',
                    'lock_status': 'LOCKED',
                    'battery_percentage': battery,
                    'last_latitude': stn.latitude,
                    'last_longitude': stn.longitude,
                }
            )
            self.stdout.write(f'Cycle docked: {cycle.cycle_number} at {stn.name}')

        self.stdout.write(self.style.SUCCESS('PalPedal data seeded successfully!'))
