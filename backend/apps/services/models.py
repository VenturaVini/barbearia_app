from django.db import models
from django.conf import settings


class Service(models.Model):
    """Modelo de Serviço"""
    name = models.CharField('Nome', max_length=100)
    description = models.TextField('Descrição')
    duration_minutes = models.PositiveIntegerField('Duração (minutos)')
    price = models.DecimalField('Preço', max_digits=10, decimal_places=2)
    image_url = models.URLField('URL da Imagem', blank=True, null=True)
    is_active = models.BooleanField('Ativo', default=True)
    created_at = models.DateTimeField('Criado em', auto_now_add=True)
    updated_at = models.DateTimeField('Atualizado em', auto_now=True)

    class Meta:
        verbose_name = 'Serviço'
        verbose_name_plural = 'Serviços'
        ordering = ['name']

    def __str__(self):
        return self.name


class BarberService(models.Model):
    """Serviços que cada barbeiro oferece"""
    barber = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='offered_services',
        verbose_name='Barbeiro',
        limit_choices_to={'is_barber': True}
    )
    service = models.ForeignKey(
        Service,
        on_delete=models.CASCADE,
        related_name='barber_services',
        verbose_name='Serviço'
    )
    created_at = models.DateTimeField('Criado em', auto_now_add=True)

    class Meta:
        unique_together = ('barber', 'service')
        verbose_name = 'Serviço do Barbeiro'
        verbose_name_plural = 'Serviços dos Barbeiros'
        ordering = ['barber__username', 'service__name']

    def __str__(self):
        return f"{self.barber.username} - {self.service.name}"
