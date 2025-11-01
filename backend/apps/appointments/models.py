from django.db import models
from apps.users.models import User
from apps.services.models import Service


class Appointment(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pendente'),
        ('confirmed', 'Confirmado'),
        ('completed', 'Concluído'),
        ('cancelled', 'Cancelado'),
    ]

    client = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='client_appointments',
        verbose_name='Cliente'
    )
    barber = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='barber_appointments',
        verbose_name='Barbeiro',
        limit_choices_to={'is_barber': True}
    )
    service = models.ForeignKey(
        Service,
        on_delete=models.CASCADE,
        related_name='appointments',
        verbose_name='Serviço'
    )
    scheduled_for = models.DateTimeField(verbose_name='Agendado para')
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending',
        verbose_name='Status'
    )
    notes = models.TextField(blank=True, verbose_name='Observações')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Criado em')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Atualizado em')

    class Meta:
        ordering = ['-scheduled_for']
        verbose_name = 'Agendamento'
        verbose_name_plural = 'Agendamentos'

    def __str__(self):
        return f"{self.client.username} - {self.service.name} - {self.scheduled_for.strftime('%d/%m/%Y %H:%M')}"

