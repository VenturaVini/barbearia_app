from rest_framework import serializers
from .models import Appointment
from apps.users.models import User
from apps.services.models import Service


class AppointmentSerializer(serializers.ModelSerializer):
    client_name = serializers.SerializerMethodField()
    barber_name = serializers.SerializerMethodField()
    service_name = serializers.SerializerMethodField()
    service_price = serializers.SerializerMethodField()
    service_duration = serializers.SerializerMethodField()

    class Meta:
        model = Appointment
        fields = [
            'id',
            'client',
            'client_name',
            'barber',
            'barber_name',
            'service',
            'service_name',
            'service_price',
            'service_duration',
            'scheduled_for',
            'status',
            'notes',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_client_name(self, obj):
        return f"{obj.client.first_name} {obj.client.last_name}".strip() or obj.client.username

    def get_barber_name(self, obj):
        return f"{obj.barber.first_name} {obj.barber.last_name}".strip() or obj.barber.username

    def get_service_name(self, obj):
        return obj.service.name

    def get_service_price(self, obj):
        return str(obj.service.price)

    def get_service_duration(self, obj):
        return obj.service.duration_minutes


class AppointmentCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Appointment
        fields = [
            'client',
            'barber',
            'service',
            'scheduled_for',
            'notes',
        ]

    def validate(self, data):
        # Validar se o barbeiro existe e está ativo
        barber = data.get('barber')
        if not barber.is_barber or not barber.is_active:
            raise serializers.ValidationError("Barbeiro inválido ou inativo")

        # Validar se o serviço existe e está ativo
        service = data.get('service')
        if not service.is_active:
            raise serializers.ValidationError("Serviço inativo")

        return data
