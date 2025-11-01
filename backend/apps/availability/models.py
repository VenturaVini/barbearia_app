from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class GlobalSchedule(models.Model):
    """
    Horário padrão global da barbearia (aplicado a novos barbeiros)
    """
    WEEKDAYS = [
        (1, 'Segunda-feira'),
        (2, 'Terça-feira'),
        (3, 'Quarta-feira'),
        (4, 'Quinta-feira'),
        (5, 'Sexta-feira'),
        (6, 'Sábado'),
        (7, 'Domingo'),
    ]
    
    weekday = models.IntegerField('Dia da Semana', choices=WEEKDAYS, unique=True)
    start_time = models.TimeField('Horário de Início', default='09:30')
    end_time = models.TimeField('Horário de Término', default='19:00')
    is_available = models.BooleanField('Disponível', default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Horário Global da Barbearia'
        verbose_name_plural = 'Horários Globais da Barbearia'
        ordering = ['weekday']

    def __str__(self):
        return f"Global - {self.get_weekday_display()}"


class BarberSchedule(models.Model):
    """
    Horário padrão de trabalho do barbeiro por dia da semana
    """
    WEEKDAYS = [
        (1, 'Segunda-feira'),
        (2, 'Terça-feira'),
        (3, 'Quarta-feira'),
        (4, 'Quinta-feira'),
        (5, 'Sexta-feira'),
        (6, 'Sábado'),
        (7, 'Domingo'),
    ]
    
    barber = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='schedules',
        limit_choices_to={'is_barber': True}
    )
    weekday = models.IntegerField('Dia da Semana', choices=WEEKDAYS)
    start_time = models.TimeField('Horário de Início')
    end_time = models.TimeField('Horário de Término')
    is_available = models.BooleanField('Disponível', default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Horário do Barbeiro'
        verbose_name_plural = 'Horários dos Barbeiros'
        unique_together = ['barber', 'weekday']
        ordering = ['weekday']

    def __str__(self):
        return f"{self.barber.username} - {self.get_weekday_display()}"


class BarberOffDay(models.Model):
    """
    Dias/períodos de folga/indisponibilidade do barbeiro
    """
    barber = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='off_days',
        limit_choices_to={'is_barber': True}
    )
    date = models.DateField('Data')
    is_all_day = models.BooleanField('Dia Todo', default=True)
    start_time = models.TimeField('Horário de Início', null=True, blank=True)
    end_time = models.TimeField('Horário de Término', null=True, blank=True)
    reason = models.CharField('Motivo', max_length=200, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Folga do Barbeiro'
        verbose_name_plural = 'Folgas dos Barbeiros'
        ordering = ['date']

    def __str__(self):
        return f"{self.barber.username} - {self.date}"
