from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    RegisterView, LoginView, ProfileView,
    StationViewSet, CycleViewSet,
    WalletDetailView, WalletTopUpView,
    StartRideView, EndRideView, ActiveRideView, RideHistoryView
)

router = DefaultRouter()
router.register(r'stations', StationViewSet, basename='station')
router.register(r'cycles', CycleViewSet, basename='cycle')

urlpatterns = [
    # Authentication
    path('auth/register/', RegisterView.as_view(), name='auth-register'),
    path('auth/login/', LoginView.as_view(), name='auth-login'),
    path('auth/profile/', ProfileView.as_view(), name='auth-profile'),

    # Wallet
    path('wallet/', WalletDetailView.as_view(), name='wallet-detail'),
    path('wallet/topup/', WalletTopUpView.as_view(), name='wallet-topup'),

    # Rides
    path('rides/start/', StartRideView.as_view(), name='ride-start'),
    path('rides/end/', EndRideView.as_view(), name='ride-end'),
    path('rides/active/', ActiveRideView.as_view(), name='ride-active'),
    path('rides/history/', RideHistoryView.as_view(), name='ride-history'),

    # Router endpoints (stations, cycles)
    path('', include(router.urls)),
]
