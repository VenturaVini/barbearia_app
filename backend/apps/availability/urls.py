from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import BarberScheduleViewSet, BarberOffDayViewSet, GlobalScheduleViewSet

router = DefaultRouter()
router.register(r'global-schedules', GlobalScheduleViewSet, basename='global-schedules')
router.register(r'schedules', BarberScheduleViewSet, basename='barber-schedules')
router.register(r'off-days', BarberOffDayViewSet, basename='barber-offdays')

urlpatterns = [
    path('', include(router.urls)),
]
