import 'package:intl/intl.dart';

/// Formatadores de dados
class Formatters {
  Formatters._();

  /// Formata preço em Real (R$)
  static String currency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  /// Formata data
  static String date(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formata hora
  static String time(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Formata data e hora
  static String dateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Formata data completa (ex: "Segunda, 29 de Outubro de 2025")
  static String dateComplet(DateTime date) {
    return DateFormat("EEEE, d 'de' MMMM 'de' y", 'pt_BR').format(date);
  }

  /// Formata data abreviada (ex: "29 Out")
  static String dateShort(DateTime date) {
    return DateFormat('d MMM', 'pt_BR').format(date);
  }

  /// Formata telefone (11) 98765-4321
  static String phone(String phone) {
    if (phone.length != 11) return phone;
    
    return '(${phone.substring(0, 2)}) ${phone.substring(2, 7)}-${phone.substring(7)}';
  }

  /// Formata duração em minutos para texto
  static String duration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    
    return '${hours}h ${remainingMinutes}min';
  }

  /// Formata status de agendamento
  static String appointmentStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDENTE':
        return 'Pendente';
      case 'CONFIRMADO':
        return 'Confirmado';
      case 'REALIZADO':
        return 'Realizado';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return status;
    }
  }

  /// Capitaliza primeira letra
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Capitaliza cada palavra
  static String capitalizeWords(String text) {
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }
}
