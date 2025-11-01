"""
URL configuration for barbearia project.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse
from rest_framework_simplejwt.views import TokenRefreshView
from apps.users.views import CustomTokenObtainPairView


def health_check(request):
    """Health check endpoint"""
    return JsonResponse({'status': 'healthy'})


urlpatterns = [
    path('admin/', admin.site.urls),
    
    # API
    path('api/', include([
        # Auth
        path('auth/', include([
            path('login/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
            path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
        ])),
        
        # Apps
        path('users/', include('apps.users.urls')),
        path('services/', include('apps.services.urls')),
        path('appointments/', include('apps.appointments.urls')),
        path('barber/availability/', include('apps.availability.urls')),
        
        # Health check
        path('health/', health_check),
    ])),
]

# Static e Media files em desenvolvimento
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
