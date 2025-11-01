from django.contrib import admin
from .models import Appointment


@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ['id', 'client', 'barber', 'service', 'scheduled_for', 'status', 'created_at']
    list_filter = ['status', 'scheduled_for', 'created_at']
    search_fields = ['client__username', 'barber__username', 'service__name']
    readonly_fields = ['created_at', 'updated_at']
    date_hierarchy = 'scheduled_for'
    
    fieldsets = (
        ('Informações do Agendamento', {
            'fields': ('client', 'barber', 'service', 'scheduled_for', 'status')
        }),
        ('Detalhes', {
            'fields': ('notes',)
        }),
        ('Metadados', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

