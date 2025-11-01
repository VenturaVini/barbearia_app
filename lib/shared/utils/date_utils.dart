import 'package:intl/intl.dart';

class AppDateUtils {
  /// Parse uma data do backend (UTC) e converte para horário local (Brazil)
  static DateTime parseFromBackend(String dateTimeString) {
    final utcDate = DateTime.parse(dateTimeString);
    return utcDate.toLocal();
  }

  /// Formata data e hora para exibição (dd/MM/yyyy HH:mm)
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(dateTime);
  }

  /// Formata apenas data (dd/MM/yyyy)
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(dateTime);
  }

  /// Formata apenas hora (HH:mm)
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm', 'pt_BR').format(dateTime);
  }

  /// Formata data para enviar ao backend (yyyy-MM-dd)
  static String formatDateForApi(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  /// Formata data e hora para enviar ao backend (yyyy-MM-ddTHH:mm:ss)
  static String formatDateTimeForApi(DateTime dateTime) {
    return DateFormat('yyyy-MM-ddTHH:mm:ss').format(dateTime);
  }

  /// Verifica se uma data já passou (considerando horário local)
  static bool isPast(DateTime dateTime) {
    return dateTime.isBefore(DateTime.now());
  }

  /// Verifica se uma data é hoje
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Verifica se um agendamento já passou considerando buffer de 30 minutos
  static bool isPastWithBuffer(DateTime scheduledTime, {int bufferMinutes = 30}) {
    final now = DateTime.now();
    final threshold = now.add(Duration(minutes: bufferMinutes));
    return scheduledTime.isBefore(threshold);
  }
}
