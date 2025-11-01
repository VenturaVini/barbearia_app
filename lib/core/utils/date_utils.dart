import 'package:intl/intl.dart';

/// Utilitários para datas
class DateUtils {
  DateUtils._();

  /// Verificar se uma data é hoje
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Verificar se uma data é amanhã
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Verificar se uma data é no passado
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Verificar se uma data é no futuro
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  /// Obter diferença em dias
  static int daysDifference(DateTime date1, DateTime date2) {
    return date1.difference(date2).inDays;
  }

  /// Obter diferença em horas
  static int hoursDifference(DateTime date1, DateTime date2) {
    return date1.difference(date2).inHours;
  }

  /// Obter diferença em minutos
  static int minutesDifference(DateTime date1, DateTime date2) {
    return date1.difference(date2).inMinutes;
  }

  /// Formatar data relativa (ex: "Hoje", "Amanhã", "Ontem")
  static String formatRelative(DateTime date) {
    if (isToday(date)) return 'Hoje';
    if (isTomorrow(date)) return 'Amanhã';
    
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Ontem';
    }

    final daysDiff = daysDifference(date, DateTime.now());
    if (daysDiff > 0 && daysDiff <= 7) {
      return 'Em $daysDiff dias';
    }
    if (daysDiff < 0 && daysDiff >= -7) {
      return '${-daysDiff} dias atrás';
    }

    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Obter nome do dia da semana
  static String getDayOfWeekName(DateTime date) {
    final weekdays = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
    return weekdays[date.weekday - 1];
  }

  /// Obter nome do mês
  static String getMonthName(int month) {
    final months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return months[month - 1];
  }

  /// Criar DateTime apenas com data (sem hora)
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Criar DateTime com hora específica
  static DateTime withTime(DateTime date, int hour, int minute) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Adicionar dias úteis (pula fins de semana)
  static DateTime addBusinessDays(DateTime date, int days) {
    DateTime result = date;
    int addedDays = 0;

    while (addedDays < days) {
      result = result.add(const Duration(days: 1));
      // Pula sábado (6) e domingo (7)
      if (result.weekday != DateTime.saturday &&
          result.weekday != DateTime.sunday) {
        addedDays++;
      }
    }

    return result;
  }

  /// Verificar se é fim de semana
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday;
  }

  /// Verificar se é dia útil
  static bool isBusinessDay(DateTime date) {
    return !isWeekend(date);
  }

  /// Obter primeiro dia do mês
  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Obter último dia do mês
  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Gerar lista de datas entre duas datas
  static List<DateTime> dateRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    DateTime current = dateOnly(start);
    final endDate = dateOnly(end);

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  /// Converter string para DateTime
  static DateTime? parseDate(String dateStr, {String format = 'dd/MM/yyyy'}) {
    try {
      return DateFormat(format).parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Verificar se pode cancelar (mínimo 3h antes)
  static bool canCancelAppointment(DateTime appointmentDate) {
    final now = DateTime.now();
    final difference = appointmentDate.difference(now);
    return difference.inHours >= 3;
  }
}
