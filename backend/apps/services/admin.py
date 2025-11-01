from django.contrib import admin
from .models import Service, BarberService


@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ['name', 'duration_minutes', 'price', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'description']
    list_editable = ['is_active']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(BarberService)
class BarberServiceAdmin(admin.ModelAdmin):
    list_display = ['barber', 'service', 'created_at']
    list_filter = ['created_at', 'barber']
    search_fields = ['barber__full_name', 'barber__email', 'service__name']
    autocomplete_fields = ['barber', 'service']
    readonly_fields = ['created_at']
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('barber', 'service')
