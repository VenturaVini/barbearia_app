import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../models/login_response.dart';
import '../models/user_model.dart';

/// Repositório de autenticação
class AuthRepository {
  /// Login
  Future<User> login({
    required String username,
    required String password,
  }) async {
    final response = await DioClient.post(
      ApiConstants.login,
      data: {
        'username': username,
        'password': password,
      },
    );

    final loginResponse = LoginResponse.fromJson(response.data);

    // Salvar tokens
    await SecureStorage.saveTokens(
      accessToken: loginResponse.access,
      refreshToken: loginResponse.refresh,
    );

    // Salvar dados do usuário
    await SecureStorage.saveUserData(
      userId: loginResponse.user.id.toString(),
      userType: loginResponse.user.toEntity().userType,
    );

    return loginResponse.user.toEntity();
  }

  /// Registro
  Future<User> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final response = await DioClient.post(
      ApiConstants.register,
      data: {
        'username': username,
        'email': email,
        'password': password,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phone != null) 'phone': phone,
      },
    );

    final loginResponse = LoginResponse.fromJson(response.data);

    // Salvar tokens
    await SecureStorage.saveTokens(
      accessToken: loginResponse.access,
      refreshToken: loginResponse.refresh,
    );

    // Salvar dados do usuário
    await SecureStorage.saveUserData(
      userId: loginResponse.user.id.toString(),
      userType: loginResponse.user.toEntity().userType,
    );

    return loginResponse.user.toEntity();
  }

  /// Obter usuário atual
  Future<User> getCurrentUser() async {
    final response = await DioClient.get(ApiConstants.me);
    final userModel = UserModel.fromJson(response.data);
    return userModel.toEntity();
  }

  /// Logout
  Future<void> logout() async {
    try {
      await DioClient.post(ApiConstants.logout);
    } catch (e) {
      // Ignorar erros de logout no servidor
    } finally {
      // Sempre limpar dados locais
      await SecureStorage.clearAll();
    }
  }

  /// Verificar se está autenticado
  Future<bool> isAuthenticated() async {
    return await SecureStorage.isAuthenticated();
  }

  /// Mudar senha
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await DioClient.post(
      ApiConstants.changePassword,
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
  }

  /// Atualizar perfil
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? username,
    String? avatarUrl,
  }) async {
    final response = await DioClient.patch(
      '/users/update_profile/',
      data: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      },
    );

    final userModel = UserModel.fromJson(response.data);
    return userModel.toEntity();
  }
}
