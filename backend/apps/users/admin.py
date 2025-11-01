from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['username', 'email', 'full_name', 'is_barber', 'is_staff', 'created_at']
    list_filter = ['is_barber', 'is_staff', 'is_active', 'created_at']
    search_fields = ['username', 'email', 'first_name', 'last_name']
    
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Informações Adicionais', {
            'fields': ('phone', 'avatar_url', 'is_barber')
        }),
    )
    
    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ('Informações Adicionais', {
            'fields': ('email', 'phone', 'is_barber')
        }),
    )
