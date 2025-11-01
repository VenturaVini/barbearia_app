import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço de armazenamento seguro
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Keys
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserType = 'user_type';

  /// Salvar tokens de autenticação
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  /// Obter access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// Obter refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Salvar dados do usuário
  static Future<void> saveUserData({
    required String userId,
    required String userType,
  }) async {
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUserType, value: userType);
  }

  /// Obter user ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  /// Obter tipo de usuário (client, barber, admin)
  static Future<String?> getUserType() async {
    return await _storage.read(key: _keyUserType);
  }

  /// Verificar se está autenticado
  static Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Limpar todos os dados (logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Deletar apenas tokens
  static Future<void> deleteTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }
}
