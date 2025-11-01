from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from rest_framework.decorators import action
from .models import BarberSchedule, BarberOffDay, GlobalSchedule
from .serializers import BarberScheduleSerializer, BarberOffDaySerializer, GlobalScheduleSerializer


class GlobalScheduleViewSet(viewsets.ModelViewSet):
    """ViewSet para horários globais da barbearia (apenas admin)"""
    serializer_class = GlobalScheduleSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]
    queryset = GlobalSchedule.objects.all()
    
    def create(self, request, *args, **kwargs):
        """Cria ou atualiza horário global"""
        weekday = request.data.get('weekday')
        
        # Verifica se já existe um horário para este dia
        existing = GlobalSchedule.objects.filter(weekday=weekday).first()
        
        if existing:
            # Atualiza o existente
            serializer = self.get_serializer(existing, data=request.data, partial=True)
            serializer.is_valid(raise_exception=True)
            serializer.save()
            return Response(serializer.data)
        else:
            # Cria novo
            return super().create(request, *args, **kwargs)


class BarberScheduleViewSet(viewsets.ModelViewSet):
    """ViewSet para horários padrão do barbeiro"""
    serializer_class = BarberScheduleSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Retorna apenas os horários do barbeiro logado"""
        return BarberSchedule.objects.filter(barber=self.request.user)

    def perform_create(self, serializer):
        """Associa o barbeiro logado ao criar horário"""
        serializer.save(barber=self.request.user)

    def perform_update(self, serializer):
        """Associa o barbeiro logado ao atualizar horário"""
        serializer.save(barber=self.request.user)


class BarberOffDayViewSet(viewsets.ModelViewSet):
    """ViewSet para dias de folga do barbeiro"""
    serializer_class = BarberOffDaySerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Retorna apenas as folgas do barbeiro logado"""
        return BarberOffDay.objects.filter(barber=self.request.user)

    def perform_create(self, serializer):
        """Associa o barbeiro logado ao criar folga"""
        serializer.save(barber=self.request.user)

    def perform_update(self, serializer):
        """Associa o barbeiro logado ao atualizar folga"""
        serializer.save(barber=self.request.user)
