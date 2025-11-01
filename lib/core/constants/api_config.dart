import 'api_constants.dart';
import 'api_constants_vps.dart';

/// Configuração que seleciona entre constantes locais e VPS.
/// Em `vps-deploy` queremos usar o VPS; isso pode ser alterado para usar
/// uma variável de ambiente/Dart define no futuro.
class ApiConfig {
  ApiConfig._();

  // Defina `useVps = true` na branch de produção/vps-deploy
  static const bool useVps = true;

  static String get baseUrl => useVps ? ApiConstantsVPS.baseUrl : ApiConstants.baseUrl;
  static Duration get connectTimeout => useVps ? ApiConstantsVPS.connectTimeout : ApiConstants.connectTimeout;
  static Duration get receiveTimeout => useVps ? ApiConstantsVPS.receiveTimeout : ApiConstants.receiveTimeout;

  // Endpoints (delegam para a classe escolhida)
  static String get login => useVps ? ApiConstantsVPS.login : ApiConstants.login;
  static String get register => useVps ? ApiConstantsVPS.register : ApiConstants.register;
  static String get refresh => useVps ? ApiConstantsVPS.refresh : ApiConstants.refresh;
  static String get logout => useVps ? ApiConstantsVPS.logout : ApiConstants.logout;
  static String get me => useVps ? ApiConstantsVPS.me : ApiConstants.me;
  static String get changePassword => useVps ? ApiConstantsVPS.changePassword : ApiConstants.changePassword;

  static String get services => useVps ? ApiConstantsVPS.services : ApiConstants.services;
  static String serviceById(int id) => useVps ? ApiConstantsVPS.serviceById(id) : ApiConstants.serviceById(id);

  static String get barbers => useVps ? ApiConstantsVPS.barbers : ApiConstants.barbers;
  static String barberById(int id) => useVps ? ApiConstantsVPS.barberById(id) : ApiConstants.barberById(id);
  static String barberAvailability(int id) => useVps ? ApiConstantsVPS.barberAvailability(id) : ApiConstants.barberAvailability(id);
  static String barberStats(int id) => useVps ? ApiConstantsVPS.barberStats(id) : ApiConstants.barberStats(id);

  static String get appointments => useVps ? ApiConstantsVPS.appointments : ApiConstants.appointments;
  static String appointmentById(int id) => useVps ? ApiConstantsVPS.appointmentById(id) : ApiConstants.appointmentById(id);
  static String rateAppointment(int id) => useVps ? ApiConstantsVPS.rateAppointment(id) : ApiConstants.rateAppointment(id);
  static String get availableSlots => useVps ? ApiConstantsVPS.availableSlots : ApiConstants.availableSlots;

  static String get unavailability => useVps ? ApiConstantsVPS.unavailability : ApiConstants.unavailability;
  static String unavailabilityById(int id) => useVps ? ApiConstantsVPS.unavailabilityById(id) : ApiConstants.unavailabilityById(id);

  static String get notifications => useVps ? ApiConstantsVPS.notifications : ApiConstants.notifications;
  static String markNotificationRead(int id) => useVps ? ApiConstantsVPS.markNotificationRead(id) : ApiConstants.markNotificationRead(id);
  static String get registerFcmToken => useVps ? ApiConstantsVPS.registerFcmToken : ApiConstants.registerFcmToken;

  static String get adminUsers => useVps ? ApiConstantsVPS.adminUsers : ApiConstants.adminUsers;
  static String adminUserById(int id) => useVps ? ApiConstantsVPS.adminUserById(id) : ApiConstants.adminUserById(id);
  static String get adminReports => useVps ? ApiConstantsVPS.adminReports : ApiConstants.adminReports;
  static String get adminDashboard => useVps ? ApiConstantsVPS.adminDashboard : ApiConstants.adminDashboard;

  static String get preferences => useVps ? ApiConstantsVPS.preferences : ApiConstants.preferences;

  static String get contentType => useVps ? ApiConstantsVPS.contentType : ApiConstants.contentType;
  static String get accept => useVps ? ApiConstantsVPS.accept : ApiConstants.accept;
}
