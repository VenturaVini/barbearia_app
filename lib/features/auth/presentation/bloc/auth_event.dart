import 'package:equatable/equatable.dart';

/// Eventos de autenticação
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Verificar se está autenticado (ao iniciar app)
class CheckAuthStatus extends AuthEvent {}

/// Login
class LoginRequested extends AuthEvent {
  final String username;
  final String password;

  const LoginRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

/// Registro
class RegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;
  final String? phone;

  const RegisterRequested({
    required this.username,
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
    this.phone,
  });

  @override
  List<Object?> get props => [
        username,
        email,
        password,
        firstName,
        lastName,
        phone,
      ];
}

/// Logout
class LogoutRequested extends AuthEvent {}

/// Obter usuário atual
class GetCurrentUser extends AuthEvent {}

/// Mudar senha
class ChangePasswordRequested extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  const ChangePasswordRequested({
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword];
}

/// Atualizar perfil
class UpdateProfileRequested extends AuthEvent {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? username;
  final String? avatarUrl;

  const UpdateProfileRequested({
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.username,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [firstName, lastName, phone, email, username, avatarUrl];
}
