"""
Utilities para o app de appointments
"""
from datetime import datetime, timedelta, time


def generate_time_slots(start_time, end_time, interval_minutes=5):
    """
    Gera horários com intervalo específico (padrão 5 minutos).
    Todos os horários terminam em 0 ou 5 (10:00, 10:05, 10:10, 10:15, etc.)
    
    Args:
        start_time: Horário de início (str 'HH:MM' ou objeto time)
        end_time: Horário de fim (str 'HH:MM' ou objeto time)
        interval_minutes: Intervalo em minutos (padrão 5)
    
    Returns:
        Lista de strings no formato 'HH:MM'
    
    Examples:
        >>> generate_time_slots('09:00', '12:00', 5)
        ['09:00', '09:05', '09:10', ..., '11:55']
        
        >>> generate_time_slots('14:00', '18:00', 10)
        ['14:00', '14:10', '14:20', ..., '17:50']
    """
    slots = []
    
    # Converter strings para objetos time se necessário
    if isinstance(start_time, str):
        start_time = datetime.strptime(start_time, '%H:%M').time()
    if isinstance(end_time, str):
        end_time = datetime.strptime(end_time, '%H:%M').time()
    
    current = datetime.combine(datetime.today(), start_time)
    end = datetime.combine(datetime.today(), end_time)
    
    while current < end:
        slots.append(current.strftime('%H:%M'))
        current += timedelta(minutes=interval_minutes)
    
    return slots


def time_to_minutes(time_str):
    """
    Converte hora (string 'HH:MM' ou objeto time) para minutos totais
    
    Args:
        time_str: String no formato 'HH:MM' ou objeto datetime.time
    
    Returns:
        int: Total de minutos
    
    Example:
        >>> time_to_minutes('10:30')
        630
        >>> time_to_minutes(time(10, 30))
        630
    """
    # Se for objeto time, converte para string
    if isinstance(time_str, time):
        time_str = time_str.strftime('%H:%M')
    
    h, m = map(int, time_str.split(':'))
    return h * 60 + m


def minutes_to_time(minutes):
    """
    Converte minutos totais para string 'HH:MM'
    
    Args:
        minutes: Total de minutos
    
    Returns:
        str: Hora no formato 'HH:MM'
    
    Example:
        >>> minutes_to_time(630)
        '10:30'
    """
    hours = minutes // 60
    mins = minutes % 60
    return f'{hours:02d}:{mins:02d}'


def get_occupied_slots(barber_id, date):
    """
    Retorna lista de horários ocupados de um barbeiro em uma data
    
    Args:
        barber_id: ID do barbeiro
        date: Data no formato 'YYYY-MM-DD' ou objeto date
    
    Returns:
        Lista de strings 'HH:MM' dos horários ocupados (no timezone local)
    """
    from .models import Appointment
    from datetime import datetime, timedelta
    from django.utils import timezone
    import pytz
    
    if isinstance(date, str):
        date = datetime.strptime(date, '%Y-%m-%d').date()
    
    # Pega timezone do Brasil
    tz = pytz.timezone('America/Sao_Paulo')
    
    # Cria datetime com início e fim do dia no timezone local
    start_of_day = tz.localize(datetime.combine(date, datetime.min.time()))
    end_of_day = tz.localize(datetime.combine(date, datetime.max.time()))
    
    appointments = Appointment.objects.filter(
        barber_id=barber_id,
        scheduled_for__gte=start_of_day,
        scheduled_for__lte=end_of_day,
        status__in=['pending', 'confirmed']
    ).select_related('service').order_by('scheduled_for')
    
    occupied = []
    for apt in appointments:
        # Converte para timezone local
        start = apt.scheduled_for.astimezone(tz)
        duration = apt.service.duration_minutes
        end = start + timedelta(minutes=duration)
        
        current = start
        # Adiciona todos os slots ocupados pelo agendamento (intervalos de 5 min)
        while current < end:
            occupied.append(current.strftime('%H:%M'))
            current += timedelta(minutes=5)
    
    return occupied


def is_time_available(time_str, occupied_slots, duration_minutes):
    """
    Verifica se um horário está disponível considerando a duração do serviço
    
    Args:
        time_str: Horário a verificar ('HH:MM')
        occupied_slots: Lista de horários ocupados
        duration_minutes: Duração do serviço em minutos
    
    Returns:
        bool: True se disponível, False se ocupado
    """
    start_minutes = time_to_minutes(time_str)
    end_minutes = start_minutes + duration_minutes
    
    # Verifica todos os slots de 5 em 5 minutos durante a duração
    current = start_minutes
    while current < end_minutes:
        if minutes_to_time(current) in occupied_slots:
            return False
        current += 5
    
    return True
