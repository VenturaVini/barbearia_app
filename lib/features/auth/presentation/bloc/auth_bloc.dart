import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/network/api_exception.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC de autenticação
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<GetCurrentUser>(_onGetCurrentUser);
    on<ChangePasswordRequested>(_onChangePasswordRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
  }

  /// Verificar status de autenticação
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final isAuth = await _authRepository.isAuthenticated();
      if (isAuth) {
        final user = await _authRepository.getCurrentUser();
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  /// Login
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      debugPrint('🔵 [AuthBloc] Tentando login com: ${event.username}');
      final user = await _authRepository.login(
        username: event.username,
        password: event.password,
      );
      debugPrint('✅ [AuthBloc] Login bem-sucedido: ${user.username}');
      emit(Authenticated(user));
    } on ApiException catch (e) {
      debugPrint('❌ [AuthBloc] ApiException: ${e.message}');
      debugPrint('   Status Code: ${e.statusCode}');
      debugPrint('   Data: ${e.data}');
      emit(AuthError(e.message));
    } catch (e) {
      debugPrint('❌ [AuthBloc] Erro genérico: $e');
      emit(const AuthError('Erro ao fazer login. Tente novamente.'));
    }
  }

  /// Registro
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await _authRepository.register(
        username: event.username,
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
      );
      emit(RegisterSuccess(user));
      emit(Authenticated(user));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Erro ao criar conta. Tente novamente.'));
    }
  }

  /// Logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await _authRepository.logout();
      emit(Unauthenticated());
    } catch (e) {
      // Mesmo com erro, fazer logout local
      emit(Unauthenticated());
    }
  }

  /// Obter usuário atual
  Future<void> _onGetCurrentUser(
    GetCurrentUser event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _authRepository.getCurrentUser();
      emit(Authenticated(user));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Erro ao carregar usuário.'));
    }
  }

  /// Mudar senha
  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    emit(AuthLoading());

    try {
      await _authRepository.changePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      );
      emit(PasswordChanged());
      
      // Voltar ao estado autenticado
      if (currentState is Authenticated) {
        emit(Authenticated(currentState.user));
      }
    } on ApiException catch (e) {
      emit(AuthError(e.message));
      // Voltar ao estado anterior
      if (currentState is Authenticated) {
        emit(Authenticated(currentState.user));
      }
    } catch (e) {
      emit(const AuthError('Erro ao alterar senha.'));
      if (currentState is Authenticated) {
        emit(Authenticated(currentState.user));
      }
    }
  }

  /// Atualizar perfil
  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    emit(AuthLoading());

    try {
      final user = await _authRepository.updateProfile(
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
        email: event.email,
        username: event.username,
        avatarUrl: event.avatarUrl,
      );
      emit(ProfileUpdated(user));
      emit(Authenticated(user));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
      if (currentState is Authenticated) {
        emit(Authenticated(currentState.user));
      }
    } catch (e) {
      emit(const AuthError('Erro ao atualizar perfil.'));
      if (currentState is Authenticated) {
        emit(Authenticated(currentState.user));
      }
    }
  }
}
