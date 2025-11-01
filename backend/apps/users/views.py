from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth import get_user_model
from .serializers import (
    UserSerializer, UserCreateSerializer, CustomTokenObtainPairSerializer,
    ChangePasswordSerializer, UpdateProfileSerializer, BarberCreateSerializer
)

User = get_user_model()


class CustomTokenObtainPairView(TokenObtainPairView):
    """View customizada de login"""
    serializer_class = CustomTokenObtainPairSerializer


class UserViewSet(viewsets.ModelViewSet):
    """ViewSet de Usuários"""
    queryset = User.objects.all()
    serializer_class = UserSerializer

    def get_permissions(self):
        """Define permissões baseadas na action"""
        if self.action == 'create':
            return [AllowAny()]
        if self.action in ['barbers']:
            return [AllowAny()]
        if self.action in ['create_barber', 'toggle_barber']:
            return [IsAdminUser()]
        return [IsAuthenticated()]

    def get_serializer_class(self):
        if self.action == 'create':
            return UserCreateSerializer
        if self.action == 'create_barber':
            return BarberCreateSerializer
        return UserSerializer

    def retrieve(self, request, pk=None):
        """Retorna dados de um usuário específico por ID"""
        try:
            user = User.objects.get(pk=pk)
            serializer = self.get_serializer(user)
            return Response(serializer.data)
        except User.DoesNotExist:
            return Response(
                {'detail': 'Usuário não encontrado.'},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=False, methods=['get'])
    def me(self, request):
        """Retorna dados do usuário atual"""
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def change_password(self, request):
        """Alterar senha do usuário"""
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user
        if not user.check_password(serializer.validated_data['old_password']):
            return Response(
                {'old_password': ['Senha atual incorreta.']},
                status=status.HTTP_400_BAD_REQUEST
            )

        user.set_password(serializer.validated_data['new_password'])
        user.save()

        return Response({'message': 'Senha alterada com sucesso.'})

    @action(detail=False, methods=['patch'])
    def update_profile(self, request):
        """Atualizar perfil do usuário"""
        serializer = UpdateProfileSerializer(
            request.user,
            data=request.data,
            partial=True
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()

        return Response(UserSerializer(request.user).data)

    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def barbers(self, request):
        """Listar apenas barbeiros (público)"""
        barbers = User.objects.filter(is_barber=True, is_active=True)
        serializer = self.get_serializer(barbers, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'], permission_classes=[IsAdminUser])
    def create_barber(self, request):
        """Criar um novo barbeiro (apenas admin)"""
        # Verificação adicional de segurança
        if not request.user.is_staff:
            return Response(
                {'detail': 'Apenas administradores podem criar barbeiros.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = BarberCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        barber = serializer.save()
        
        return Response(
            UserSerializer(barber).data,
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['patch'], permission_classes=[IsAdminUser])
    def toggle_barber(self, request, pk=None):
        """Alternar status de barbeiro (apenas admin)"""
        # Verificação adicional de segurança
        if not request.user.is_staff:
            return Response(
                {'detail': 'Apenas administradores podem alterar status de barbeiro.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        user = self.get_object()
        user.is_barber = not user.is_barber
        user.save()
        
        return Response(UserSerializer(user).data)

    @action(detail=False, methods=['post'], permission_classes=[AllowAny])
    def check_email(self, request):
        """Verificar se email já existe"""
        email = request.data.get('email', '').strip().lower()
        if not email:
            return Response({'exists': False})
        
        exists = User.objects.filter(email__iexact=email).exists()
        return Response({'exists': exists})

    @action(detail=False, methods=['post'], permission_classes=[AllowAny])
    def check_username(self, request):
        """Verificar se username já existe"""
        username = request.data.get('username', '').strip().lower()
        if not username:
            return Response({'exists': False})
        
        exists = User.objects.filter(username__iexact=username).exists()
        return Response({'exists': exists})

    @action(detail=False, methods=['post'])
    def verify_password(self, request):
        """Verifica se a senha fornecida está correta"""
        password = request.data.get('password')
        
        if not password:
            return Response(
                {"error": "password é obrigatório"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if request.user.check_password(password):
            return Response({"valid": True})
        else:
            return Response(
                {"valid": False, "error": "Senha incorreta"},
                status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=False, methods=['post'], permission_classes=[IsAdminUser])
    def reset_database(self, request):
        """
        ATENÇÃO: Endpoint PERIGOSO que deleta TODOS os dados!
        Use apenas em desenvolvimento.
        Em produção, desabilite ou adicione mais validações.
        """
        if not request.user.is_superuser:
            return Response(
                {"error": "Apenas superusuários podem resetar o banco de dados"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            from apps.appointments.models import Appointment
            from apps.services.models import Service, BarberService
            
            # Deletar agendamentos
            deleted_appointments = Appointment.objects.all().delete()
            
            # Deletar relações barbeiro-serviço
            deleted_barber_services = BarberService.objects.all().delete()
            
            # Deletar serviços
            deleted_services = Service.objects.all().delete()
            
            # Deletar barbeiros (não admin/superuser)
            deleted_barbers = User.objects.filter(
                is_barber=True,
                is_superuser=False
            ).delete()
            
            # Deletar clientes (não staff, não barbeiro)
            deleted_clients = User.objects.filter(
                is_staff=False,
                is_barber=False
            ).delete()
            
            return Response({
                "message": "Database reset successfully",
                "deleted": {
                    "appointments": deleted_appointments[0] if deleted_appointments else 0,
                    "barber_services": deleted_barber_services[0] if deleted_barber_services else 0,
                    "services": deleted_services[0] if deleted_services else 0,
                    "barbers": deleted_barbers[0] if deleted_barbers else 0,
                    "clients": deleted_clients[0] if deleted_clients else 0,
                }
            }, status=status.HTTP_200_OK)
        
        except Exception as e:
            return Response({
                "error": f"Erro ao resetar banco: {str(e)}"
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
