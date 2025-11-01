import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Estados de autenticação
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class AuthInitial extends AuthState {}

/// Carregando
class AuthLoading extends AuthState {}

/// Autenticado
class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Não autenticado
class Unauthenticated extends AuthState {}

/// Erro de autenticação
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Registro bem-sucedido
class RegisterSuccess extends AuthState {
  final User user;

  const RegisterSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

/// Senha alterada com sucesso
class PasswordChanged extends AuthState {}

/// Perfil atualizado
class ProfileUpdated extends AuthState {
  final User user;

  const ProfileUpdated(this.user);

  @override
  List<Object?> get props => [user];
}
