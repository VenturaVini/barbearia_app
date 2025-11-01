from rest_framework import serializers
from .models import Service, BarberService


class ServiceSerializer(serializers.ModelSerializer):
    """Serializer de Serviço"""
    
    class Meta:
        model = Service
        fields = [
            'id', 'name', 'description', 'duration_minutes',
            'price', 'image_url', 'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class BarberServiceSerializer(serializers.ModelSerializer):
    """Serializer de Serviço do Barbeiro"""
    service_details = ServiceSerializer(source='service', read_only=True)
    barber_name = serializers.CharField(source='barber.username', read_only=True)
    
    class Meta:
        model = BarberService
        fields = ['id', 'barber', 'service', 'service_details', 'barber_name', 'created_at']
        read_only_fields = ['id', 'created_at']
