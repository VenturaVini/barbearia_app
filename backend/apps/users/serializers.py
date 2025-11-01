from rest_framework import serializers
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    """Serializer de Usuário"""
    user_type = serializers.ReadOnlyField()
    full_name = serializers.ReadOnlyField()

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'phone', 'avatar_url', 'is_barber', 'is_staff',
            'user_type', 'full_name', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'is_staff', 'created_at', 'updated_at']


class UserCreateSerializer(serializers.ModelSerializer):
    """Serializer para criação de usuário (cliente comum apenas)"""
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'first_name',
            'last_name', 'phone'
        ]

    def create(self, validated_data):
        # Garante que usuários criados via registro são sempre clientes (is_barber=False)
        validated_data['is_barber'] = False
        user = User.objects.create_user(**validated_data)
        return user


class BarberCreateSerializer(serializers.ModelSerializer):
    """Serializer para criação de barbeiros (apenas admin)"""
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'first_name',
            'last_name', 'phone', 'avatar_url'
        ]

    def create(self, validated_data):
        # Força is_barber=True para barbeiros
        validated_data['is_barber'] = True
        user = User.objects.create_user(**validated_data)
        return user


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Serializer customizado de Login com dados do usuário"""
    
    def validate(self, attrs):
        data = super().validate(attrs)
        
        # Adicionar dados do usuário ao response
        user_data = UserSerializer(self.user).data
        data['user'] = user_data
        
        return data


class ChangePasswordSerializer(serializers.Serializer):
    """Serializer para mudança de senha"""
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, min_length=6)


class UpdateProfileSerializer(serializers.ModelSerializer):
    """Serializer para atualização de perfil"""
    
    # Username e email são opcionais (clientes não podem alterar)
    username = serializers.CharField(required=False)
    email = serializers.EmailField(required=False)
    
    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'phone', 'avatar_url', 'username', 'email']
    
    def validate_username(self, value):
        """Validar que username é único (exceto para o usuário atual)"""
        if User.objects.filter(username=value).exclude(id=self.instance.id).exists():
            raise serializers.ValidationError("Este nome de usuário já está em uso.")
        return value
    
    def validate_email(self, value):
        """Validar que email é único (exceto para o usuário atual)"""
        if User.objects.filter(email=value).exclude(id=self.instance.id).exists():
            raise serializers.ValidationError("Este email já está em uso.")
        return value
