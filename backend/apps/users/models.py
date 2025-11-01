from django.contrib.auth.models import AbstractUser
from django.db import models
from phonenumber_field.modelfields import PhoneNumberField


class User(AbstractUser):
    """
    Modelo customizado de usuário
    """
    email = models.EmailField('Email', unique=True)
    phone = PhoneNumberField('Telefone', blank=True, null=True)
    avatar_url = models.URLField('Avatar URL', blank=True, null=True)
    is_barber = models.BooleanField('É Barbeiro', default=False)
    created_at = models.DateTimeField('Criado em', auto_now_add=True)
    updated_at = models.DateTimeField('Atualizado em', auto_now=True)

    class Meta:
        verbose_name = 'Usuário'
        verbose_name_plural = 'Usuários'
        ordering = ['-created_at']

    def __str__(self):
        return self.username

    @property
    def user_type(self):
        """Retorna o tipo de usuário"""
        if self.is_staff:
            return 'admin'
        if self.is_barber:
            return 'barber'
        return 'client'

    @property
    def full_name(self):
        """Retorna o nome completo"""
        return f"{self.first_name} {self.last_name}".strip() or self.username
