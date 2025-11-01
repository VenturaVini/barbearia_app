from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from .models import Service, BarberService
from .serializers import ServiceSerializer, BarberServiceSerializer

User = get_user_model()


class ServiceViewSet(viewsets.ModelViewSet):
    """ViewSet de Serviços"""
    queryset = Service.objects.filter(is_active=True)
    serializer_class = ServiceSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['is_active']
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'price', 'duration_minutes']

    def get_permissions(self):
        """
        Listagem e visualização: Público (AllowAny)
        Criar/editar/deletar: Apenas admin
        """
        if self.action in ['list', 'retrieve']:
            return [AllowAny()]
        if self.action in ['create', 'update', 'partial_update', 'destroy', 'toggle']:
            return [IsAdminUser()]
        return [IsAuthenticated()]

    def get_queryset(self):
        """Admin vê todos, outros usuários só os ativos"""
        if self.request.user.is_staff:
            return Service.objects.all()
        return Service.objects.filter(is_active=True)

    @action(detail=True, methods=['patch'], permission_classes=[IsAdminUser])
    def toggle(self, request, pk=None):
        """Ativar/desativar serviço"""
        service = self.get_object()
        service.is_active = not service.is_active
        service.save()
        
        status_text = 'ativado' if service.is_active else 'desativado'
        return Response({
            'message': f'Serviço {status_text} com sucesso!',
            'is_active': service.is_active
        })


class BarberServiceViewSet(viewsets.ViewSet):
    """ViewSet de Serviços do Barbeiro"""
    permission_classes = [IsAuthenticated]
    
    def list(self, request):
        """Lista serviços que o barbeiro logado oferece"""
        if not request.user.is_barber:
            return Response(
                {"error": "Apenas barbeiros podem acessar este recurso"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        barber_services = BarberService.objects.filter(
            barber=request.user
        ).select_related('service')
        
        # Retorna apenas os serviços (não o BarberService)
        services = [bs.service for bs in barber_services]
        serializer = ServiceSerializer(services, many=True)
        return Response(serializer.data)
    
    def create(self, request):
        """Adiciona serviço ao barbeiro"""
        if not request.user.is_barber:
            return Response(
                {"error": "Apenas barbeiros podem acessar este recurso"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        service_id = request.data.get('service_id')
        if not service_id:
            return Response(
                {"error": "service_id é obrigatório"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            service = Service.objects.get(id=service_id, is_active=True)
        except Service.DoesNotExist:
            return Response(
                {"error": "Serviço não encontrado ou inativo"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        barber_service, created = BarberService.objects.get_or_create(
            barber=request.user,
            service=service
        )
        
        if created:
            return Response(
                {"message": "Serviço adicionado com sucesso"},
                status=status.HTTP_201_CREATED
            )
        else:
            return Response(
                {"message": "Serviço já estava adicionado"},
                status=status.HTTP_200_OK
            )
    
    def destroy(self, request, pk=None):
        """Remove serviço do barbeiro"""
        if not request.user.is_barber:
            return Response(
                {"error": "Apenas barbeiros podem acessar este recurso"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            barber_service = BarberService.objects.get(
                barber=request.user,
                service_id=pk
            )
            barber_service.delete()
            return Response(
                {"message": "Serviço removido com sucesso"},
                status=status.HTTP_200_OK
            )
        except BarberService.DoesNotExist:
            return Response(
                {"error": "Serviço não encontrado na sua lista"},
                status=status.HTTP_404_NOT_FOUND
            )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def barber_services_list(request, barber_id):
    """Lista serviços oferecidos por um barbeiro específico"""
    try:
        barber = User.objects.get(id=barber_id, is_barber=True, is_active=True)
    except User.DoesNotExist:
        return Response(
            {"error": "Barbeiro não encontrado"},
            status=status.HTTP_404_NOT_FOUND
        )
    
    barber_services = BarberService.objects.filter(
        barber=barber
    ).select_related('service').filter(service__is_active=True)
    
    # Se o barbeiro não tem serviços configurados, retorna todos
    if not barber_services.exists():
        services = Service.objects.filter(is_active=True)
    else:
        services = [bs.service for bs in barber_services]
    
    serializer = ServiceSerializer(services, many=True)
    return Response(serializer.data)
