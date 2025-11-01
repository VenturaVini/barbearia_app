from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ServiceViewSet, BarberServiceViewSet, barber_services_list

router = DefaultRouter()
router.register(r'', ServiceViewSet, basename='service')

barber_router = DefaultRouter()
barber_router.register(r'my-services', BarberServiceViewSet, basename='barber-service')

urlpatterns = [
    path('', include(router.urls)),
    path('barber/', include(barber_router.urls)),
    path('barber/<int:barber_id>/services/', barber_services_list, name='barber-services-list'),
]
