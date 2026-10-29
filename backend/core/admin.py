from django.contrib import admin
from .models import Wallet, WalletTransaction, Station, Cycle, RideBooking

@admin.register(Wallet)
class WalletAdmin(admin.ModelAdmin):
    list_display = ('user', 'balance', 'updated_at')
    search_fields = ('user__username', 'user__email')
    readonly_fields = ('id', 'created_at', 'updated_at')

@admin.register(WalletTransaction)
class WalletTransactionAdmin(admin.ModelAdmin):
    list_display = ('wallet', 'transaction_type', 'amount', 'created_at', 'description')
    list_filter = ('transaction_type', 'created_at')
    search_fields = ('wallet__user__username', 'description')
    readonly_fields = ('id', 'created_at')

@admin.register(Station)
class StationAdmin(admin.ModelAdmin):
    list_display = ('name', 'capacity', 'available_cycles_count', 'is_active', 'latitude', 'longitude')
    search_fields = ('name', 'address')
    list_filter = ('is_active',)

@admin.register(Cycle)
class CycleAdmin(admin.ModelAdmin):
    list_display = ('cycle_number', 'qr_code', 'current_station', 'status', 'lock_status', 'battery_percentage', 'updated_at')
    list_filter = ('status', 'lock_status', 'current_station')
    search_fields = ('cycle_number', 'qr_code')
    readonly_fields = ('id', 'updated_at')

@admin.register(RideBooking)
class RideBookingAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'cycle', 'start_station', 'end_station', 'status', 'duration_minutes', 'total_fare', 'start_time')
    list_filter = ('status', 'start_time')
    search_fields = ('user__username', 'cycle__cycle_number')
    readonly_fields = ('id', 'start_time')
