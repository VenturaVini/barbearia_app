from django.core.management.base import BaseCommand
from apps.services.models import Service


class Command(BaseCommand):
    help = 'Cria serviços padrão'

    def handle(self, *args, **options):
        services_data = [
            {
                'name': 'Corte Simples',
                'description': 'Corte de cabelo masculino tradicional',
                'duration_minutes': 30,
                'price': 35.00,
            },
            {
                'name': 'Corte + Barba',
                'description': 'Corte de cabelo + barba completa',
                'duration_minutes': 45,
                'price': 50.00,
            },
            {
                'name': 'Barba Completa',
                'description': 'Barba com toalha quente e finalização',
                'duration_minutes': 30,
                'price': 30.00,
            },
            {
                'name': 'Sobrancelha',
                'description': 'Design de sobrancelha masculina',
                'duration_minutes': 15,
                'price': 15.00,
            },
            {
                'name': 'Corte Premium',
                'description': 'Corte moderno com lavagem e finalização',
                'duration_minutes': 60,
                'price': 70.00,
            },
            {
                'name': 'Corte Infantil',
                'description': 'Corte de cabelo para crianças até 12 anos',
                'duration_minutes': 25,
                'price': 25.00,
            },
            {
                'name': 'Platinado/Luzes',
                'description': 'Descoloração e aplicação de luzes',
                'duration_minutes': 120,
                'price': 150.00,
            },
            {
                'name': 'Relaxamento',
                'description': 'Relaxamento capilar',
                'duration_minutes': 90,
                'price': 80.00,
            },
        ]

        created_count = 0
        for service_data in services_data:
            service, created = Service.objects.get_or_create(
                name=service_data['name'],
                defaults=service_data
            )
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'✓ Serviço "{service.name}" criado')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'- Serviço "{service.name}" já existe')
                )

        self.stdout.write(
            self.style.SUCCESS(f'\n{created_count} serviço(s) criado(s) com sucesso!')
        )
