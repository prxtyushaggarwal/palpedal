import uuid
from decimal import Decimal
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone

class Wallet(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='wallet')
    balance = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username}'s Wallet (${self.balance})"

class WalletTransaction(models.Model):
    TRANSACTION_TYPES = [
        ('CREDIT', 'Credit / Top-up'),
        ('DEBIT', 'Debit / Ride Fare'),
        ('REFUND', 'Refund'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    wallet = models.ForeignKey(Wallet, on_delete=models.CASCADE, related_name='transactions')
    transaction_type = models.CharField(max_length=10, choices=TRANSACTION_TYPES)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    description = models.CharField(max_length=255)
    ride = models.ForeignKey('RideBooking', on_delete=models.SET_NULL, null=True, blank=True, related_name='wallet_transactions')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.transaction_type}] ${self.amount} - {self.wallet.user.username}"

class Station(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=150)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    address = models.CharField(max_length=255, blank=True)
    capacity = models.PositiveIntegerField(default=15)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

    @property
    def available_cycles_count(self):
        return self.cycles.filter(status='AVAILABLE').count()

class Cycle(models.Model):
    STATUS_CHOICES = [
        ('AVAILABLE', 'Available'),
        ('IN_USE', 'In Use / Rented'),
        ('MAINTENANCE', 'Under Maintenance'),
    ]

    LOCK_CHOICES = [
        ('LOCKED', 'Locked'),
        ('UNLOCKED', 'Unlocked'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cycle_number = models.CharField(max_length=50, unique=True)
    qr_code = models.CharField(max_length=100, unique=True, db_index=True)
    current_station = models.ForeignKey(Station, on_delete=models.SET_NULL, null=True, blank=True, related_name='cycles')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='AVAILABLE')
    lock_status = models.CharField(max_length=20, choices=LOCK_CHOICES, default='LOCKED')
    battery_percentage = models.PositiveIntegerField(default=100)
    last_latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    last_longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Cycle {self.cycle_number} ({self.status})"

class RideBooking(models.Model):
    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
    ]

    BASE_FARE = Decimal('1.50')
    PER_MINUTE_RATE = Decimal('0.15')

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='rides')
    cycle = models.ForeignKey(Cycle, on_delete=models.CASCADE, related_name='rides')
    start_station = models.ForeignKey(Station, on_delete=models.SET_NULL, null=True, related_name='departing_rides')
    end_station = models.ForeignKey(Station, on_delete=models.SET_NULL, null=True, blank=True, related_name='arriving_rides')
    start_time = models.DateTimeField(default=timezone.now)
    end_time = models.DateTimeField(null=True, blank=True)
    duration_minutes = models.PositiveIntegerField(default=0)
    total_fare = models.DecimalField(max_digits=8, decimal_places=2, default=Decimal('0.00'))
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ACTIVE')

    class Meta:
        ordering = ['-start_time']

    def __str__(self):
        return f"Ride {self.id} by {self.user.username} ({self.status})"

    def calculate_fare(self, end_timestamp=None):
        if not end_timestamp:
            end_timestamp = timezone.now()
        duration_delta = end_timestamp - self.start_time
        mins = max(1, int(duration_delta.total_seconds() // 60))
        fare = self.BASE_FARE + (Decimal(mins) * self.PER_MINUTE_RATE)
        return mins, fare
