from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
from django.utils import timezone
from datetime import datetime, time, timedelta
from .models import Appointment
from .serializers import AppointmentSerializer, AppointmentCreateSerializer
from .utils import generate_time_slots, get_occupied_slots, is_time_available
from apps.users.models import User
import pytz


class AppointmentViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == 'create':
            return AppointmentCreateSerializer
        return AppointmentSerializer

    def get_queryset(self):
        user = self.request.user
        # Usuários veem seus próprios agendamentos (como cliente ou barbeiro)
        return Appointment.objects.filter(
            Q(client=user) | Q(barber=user)
        ).select_related('client', 'barber', 'service').order_by('-scheduled_for')

    def create(self, request, *args, **kwargs):
        # Define o cliente como o usuário autenticado
        data = request.data.copy()
        data['client'] = request.user.id

        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)

        # Retorna com o serializer completo para incluir os campos extras
        appointment = serializer.instance
        response_serializer = AppointmentSerializer(appointment)
        
        return Response(
            response_serializer.data,
            status=status.HTTP_201_CREATED
        )

    @action(detail=False, methods=['get'])
    def barber_schedule(self, request):
        """
        Endpoint para o barbeiro visualizar sua agenda diária
        GET /appointments/barber_schedule/?date=YYYY-MM-DD
        """
        # Verificar se o usuário é barbeiro
        if not request.user.is_barber:
            return Response(
                {'error': 'Apenas barbeiros podem acessar esta funcionalidade'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Obter a data do parâmetro
        date_str = request.query_params.get('date')
        if not date_str:
            return Response(
                {'error': 'Parâmetro date é obrigatório (formato: YYYY-MM-DD)'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response(
                {'error': 'Formato de data inválido. Use YYYY-MM-DD'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Buscar agendamentos do barbeiro para a data especificada
        appointments = Appointment.objects.filter(
            barber=request.user,
            scheduled_for__date=date
        ).select_related('client', 'service').order_by('scheduled_for')

        serializer = self.get_serializer(appointments, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        """
        Endpoint para atualizar o status de um agendamento
        PATCH /appointments/{id}/update_status/
        Body: {"status": "confirmed"|"completed"|"cancelled"}
        """
        appointment = self.get_object()

        # Apenas o barbeiro pode alterar o status
        if appointment.barber != request.user:
            return Response(
                {'error': 'Apenas o barbeiro responsável pode alterar o status'},
                status=status.HTTP_403_FORBIDDEN
            )

        new_status = request.data.get('status')
        valid_statuses = ['pending', 'confirmed', 'completed', 'cancelled']
        
        if not new_status or new_status not in valid_statuses:
            return Response(
                {'error': f'Status inválido. Use um dos seguintes: {", ".join(valid_statuses)}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        appointment.status = new_status
        appointment.save()

        serializer = self.get_serializer(appointment)
        return Response(serializer.data)

    @action(detail=True, methods=['patch'])
    def cancel(self, request, pk=None):
        """
        Endpoint para o cliente cancelar um agendamento
        PATCH /appointments/{id}/cancel/
        
        Regra: Só pode cancelar com pelo menos 30 minutos de antecedência
        """
        appointment = self.get_object()

        # Apenas o cliente pode cancelar
        if appointment.client != request.user:
            return Response(
                {'error': 'Apenas o cliente pode cancelar o agendamento'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Não pode cancelar se já estiver concluído
        if appointment.status == 'completed':
            return Response(
                {'error': 'Não é possível cancelar um agendamento já concluído'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Verificar se faltam pelo menos 30 minutos
        tz = pytz.timezone('America/Sao_Paulo')
        now = timezone.now().astimezone(tz)
        time_until_appointment = appointment.scheduled_for - now
        
        if time_until_appointment.total_seconds() < 30 * 60:  # 30 minutos em segundos
            return Response(
                {'error': 'Cancelamento permitido apenas com 30 minutos de antecedência'},
                status=status.HTTP_400_BAD_REQUEST
            )

        appointment.status = 'cancelled'
        appointment.save()

        serializer = self.get_serializer(appointment)
        return Response({
            'message': 'Agendamento cancelado com sucesso',
            'appointment': serializer.data
        })

    @action(detail=False, methods=['get'])
    def available_times(self, request):
        """
        Endpoint para listar horários disponíveis de um barbeiro
        GET /appointments/available_times/?barber_id=1&date=YYYY-MM-DD&service_id=1
        """
        barber_id = request.query_params.get('barber_id')
        date_str = request.query_params.get('date')
        service_id = request.query_params.get('service_id')
        
        if not all([barber_id, date_str]):
            return Response(
                {'error': 'Parâmetros barber_id e date são obrigatórios'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            barber = User.objects.get(id=barber_id, is_barber=True)
        except User.DoesNotExist:
            return Response(
                {'error': 'Barbeiro não encontrado'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        try:
            date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response(
                {'error': 'Formato de data inválido. Use YYYY-MM-DD'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Verificar se o barbeiro tem disponibilidade configurada para este dia
        weekday = date.weekday()
        
        from apps.availability.models import BarberSchedule, GlobalSchedule
        
        # Primeiro, verifica se o barbeiro tem configuração própria
        barber_schedule = BarberSchedule.objects.filter(
            barber=barber,
            weekday=weekday + 1,  # Django weekday é 0-6, BarberSchedule é 1-7
        ).first()
        
        # Se o barbeiro não tem configuração própria, usa a configuração global
        if not barber_schedule:
            global_schedule = GlobalSchedule.objects.filter(
                weekday=weekday + 1
            ).first()
            
            # Se existe configuração global E está indisponível, retorna vazio
            if global_schedule and not global_schedule.is_available:
                return Response({
                    'barber_id': barber_id,
                    'barber_name': barber.get_full_name() or barber.username,
                    'date': date_str,
                    'service_duration': 30,
                    'available_times': [],
                    'total_slots': 0,
                    'message': 'Este barbeiro não está disponível neste dia (configuração global)'
                })
            # Se não existe configuração global, assume disponível (backward compatibility)
        else:
            # Se barbeiro tem configuração própria E está indisponível, retorna vazio
            if not barber_schedule.is_available:
                return Response({
                    'barber_id': barber_id,
                    'barber_name': barber.get_full_name() or barber.username,
                    'date': date_str,
                    'service_duration': 30,
                    'available_times': [],
                    'total_slots': 0,
                    'message': 'Este barbeiro não está disponível neste dia'
                })
        
        # Duração do serviço (padrão 30 minutos se não especificado)
        duration_minutes = 30
        if service_id:
            from apps.services.models import Service
            try:
                service = Service.objects.get(id=service_id)
                duration_minutes = service.duration_minutes
            except Service.DoesNotExist:
                pass
        
        # Gerar todos os slots possíveis (8h às 21h, intervalos de 5 minutos)
        all_slots = generate_time_slots(time(8, 0), time(21, 0), 5)
        
        # Obter slots ocupados
        occupied = get_occupied_slots(barber_id, date)
        
        # Filtrar apenas os horários disponíveis considerando a duração
        available = []
        for slot in all_slots:
            if is_time_available(slot, occupied, duration_minutes):
                available.append(slot)
        
        # Se a data é hoje, filtrar horários que já passaram + buffer de 20 minutos
        tz = pytz.timezone('America/Sao_Paulo')
        now = timezone.now().astimezone(tz)
        
        if date == now.date():
            # Adicionar 20 minutos ao horário atual (tempo mínimo para agendar)
            min_time = now + timedelta(minutes=20)
            
            # Arredondar para o próximo slot de 5 minutos
            minutes = min_time.minute
            rounded_minutes = ((minutes + 4) // 5) * 5
            
            if rounded_minutes >= 60:
                min_time = min_time.replace(hour=min_time.hour + 1, minute=0, second=0, microsecond=0)
            else:
                min_time = min_time.replace(minute=rounded_minutes, second=0, microsecond=0)
            
            # Converter para string HH:MM para comparação
            min_time_str = min_time.strftime('%H:%M')
            
            # Filtrar apenas horários >= min_time_str
            available = [slot for slot in available if slot >= min_time_str]
        
        return Response({
            'barber_id': barber_id,
            'barber_name': barber.get_full_name() or barber.username,
            'date': date_str,
            'service_duration': duration_minutes,
            'available_times': available,
            'total_slots': len(available)
        })

    @action(detail=False, methods=['get'], url_path='barber_stats')
    def barber_stats(self, request):
        """
        Retorna estatísticas do barbeiro logado
        GET /appointments/barber_stats/
        """
        if not request.user.is_barber:
            return Response(
                {'error': 'Apenas barbeiros podem acessar esta rota'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        barber = request.user
        tz = pytz.timezone('America/Sao_Paulo')
        now = timezone.now().astimezone(tz)
        
        # Total de atendimentos concluídos (todos os tempos)
        total_completed = Appointment.objects.filter(
            barber=barber,
            status='completed'
        ).count()
        
        # Atendimentos concluídos hoje
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        today_end = now.replace(hour=23, minute=59, second=59, microsecond=999999)
        
        today_completed = Appointment.objects.filter(
            barber=barber,
            status='completed',
            scheduled_for__gte=today_start,
            scheduled_for__lte=today_end
        ).count()
        
        # Atendimentos concluídos no mês atual
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        # Último dia do mês
        if now.month == 12:
            month_end = now.replace(year=now.year + 1, month=1, day=1, hour=0, minute=0, second=0, microsecond=0) - timedelta(seconds=1)
        else:
            month_end = now.replace(month=now.month + 1, day=1, hour=0, minute=0, second=0, microsecond=0) - timedelta(seconds=1)
        
        month_completed = Appointment.objects.filter(
            barber=barber,
            status='completed',
            scheduled_for__gte=month_start,
            scheduled_for__lte=month_end
        ).count()
        
        return Response({
            'total_completed': total_completed,
            'today_completed': today_completed,
            'month_completed': month_completed,
        })
