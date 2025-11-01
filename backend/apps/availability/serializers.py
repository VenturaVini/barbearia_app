from rest_framework import serializers
from .models import BarberSchedule, BarberOffDay, GlobalSchedule


class GlobalScheduleSerializer(serializers.ModelSerializer):
    class Meta:
        model = GlobalSchedule
        fields = ['id', 'weekday', 'start_time', 'end_time', 'is_available', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']


class BarberScheduleSerializer(serializers.ModelSerializer):
    class Meta:
        model = BarberSchedule
        fields = ['id', 'barber', 'weekday', 'start_time', 'end_time', 'is_available', 'created_at', 'updated_at']
        read_only_fields = ['barber', 'created_at', 'updated_at']


class BarberOffDaySerializer(serializers.ModelSerializer):
    class Meta:
        model = BarberOffDay
        fields = ['id', 'barber', 'date', 'is_all_day', 'start_time', 'end_time', 'reason', 'created_at', 'updated_at']
        read_only_fields = ['barber', 'created_at', 'updated_at']
