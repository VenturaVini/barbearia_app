import '../../../../core/network/dio_client.dart';

/// Serviço para validações de usuário
class UserValidationService {
  /// Verificar se email já existe
  static Future<bool> emailExists(String email) async {
    try {
      // Endpoint para verificar email (precisa ser criado no backend)
      final response = await DioClient.post(
        '/users/check_email/',
        data: {'email': email},
      );
      return response.data['exists'] ?? false;
    } catch (e) {
      // Em caso de erro, assumir que não existe (não bloquear o usuário)
      return false;
    }
  }

  /// Verificar se username já existe
  static Future<bool> usernameExists(String username) async {
    try {
      // Endpoint para verificar username (precisa ser criado no backend)
      final response = await DioClient.post(
        '/users/check_username/',
        data: {'username': username},
      );
      return response.data['exists'] ?? false;
    } catch (e) {
      // Em caso de erro, assumir que não existe (não bloquear o usuário)
      return false;
    }
  }
}
