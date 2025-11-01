/// Constantes da API (template para VPS / produção)
/// Copie/renomeie este arquivo e atualize `_host` com o IP ou domínio do seu VPS
/// Exemplo: static const String _host = 'app.meudominio.com';
class ApiConstantsVPS {
  ApiConstantsVPS._();

  // ============================================
  // 🔧 CONFIGURAÇÃO PARA PRODUÇÃO (VPS)
  // ============================================
  // Substitua pelo IP/DOMÍNIO do seu servidor VPS
  static const String _host = 'SEU_VPS_IP_OU_DOMINIO';

  // Porta do backend (ex: 7891)
  static const String _port = '7891';

  // ============================================

  // Base URL - Gerada automaticamente
  static String get baseUrl => 'http://$_host:$_port/api';

  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Endpoints Auth
  static const String login = '/auth/login/';
  static const String register = '/users/';
  static const String refresh = '/auth/refresh/';
  static const String logout = '/auth/logout/';
  static const String me = '/users/me/';
  static const String changePassword = '/users/change_password/';

  // Endpoints Services
  static const String services = '/services/';
  static String serviceById(int id) => '/services/$id/';

  // Endpoints Barbers
  static const String barbers = '/barbers/';
  static String barberById(int id) => '/barbers/$id/';
  static String barberAvailability(int id) => '/barbers/$id/availability/';
  static String barberStats(int id) => '/barbers/$id/stats/';

  // Endpoints Appointments
  static const String appointments = '/appointments/';
  static String appointmentById(int id) => '/appointments/$id/';
  static String rateAppointment(int id) => '/appointments/$id/rate/';
  static const String availableSlots = '/appointments/available-slots/';

  // Endpoints Unavailability
  static const String unavailability = '/unavailability/';
  static String unavailabilityById(int id) => '/unavailability/$id/';

  // Endpoints Notifications
  static const String notifications = '/notifications/';
  static String markNotificationRead(int id) => '/notifications/$id/read/';
  static const String registerFcmToken = '/notifications/register-token/';

  // Endpoints Admin
  static const String adminUsers = '/admin/users/';
  static String adminUserById(int id) => '/admin/users/$id/';
  static const String adminReports = '/admin/reports/';
  static const String adminDashboard = '/admin/dashboard/';

  // Endpoints Preferences
  static const String preferences = '/preferences/';

  // Headers
  static const String contentType = 'application/json';
  static const String accept = 'application/json';
}
