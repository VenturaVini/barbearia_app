import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de armazenamento local (não criptografado)
class SharedPrefs {
  static SharedPreferences? _prefs;

  // Keys
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyFcmToken = 'fcm_token';

  /// Inicializar SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Obter instância
  static SharedPreferences get instance {
    if (_prefs == null) {
      throw Exception('SharedPreferences não inicializado. Chame SharedPrefs.init() primeiro.');
    }
    return _prefs!;
  }

  // Onboarding
  static Future<void> setOnboardingCompleted(bool completed) async {
    await instance.setBool(_keyOnboardingCompleted, completed);
  }

  static bool getOnboardingCompleted() {
    return instance.getBool(_keyOnboardingCompleted) ?? false;
  }

  // Theme Mode
  static Future<void> setThemeMode(String mode) async {
    await instance.setString(_keyThemeMode, mode);
  }

  static String getThemeMode() {
    return instance.getString(_keyThemeMode) ?? 'dark';
  }

  // Language
  static Future<void> setLanguage(String language) async {
    await instance.setString(_keyLanguage, language);
  }

  static String getLanguage() {
    return instance.getString(_keyLanguage) ?? 'pt_BR';
  }

  // Notifications
  static Future<void> setNotificationsEnabled(bool enabled) async {
    await instance.setBool(_keyNotificationsEnabled, enabled);
  }

  static bool getNotificationsEnabled() {
    return instance.getBool(_keyNotificationsEnabled) ?? true;
  }

  // FCM Token
  static Future<void> setFcmToken(String token) async {
    await instance.setString(_keyFcmToken, token);
  }

  static String? getFcmToken() {
    return instance.getString(_keyFcmToken);
  }

  /// Limpar todas as preferências
  static Future<void> clearAll() async {
    await instance.clear();
  }
}
