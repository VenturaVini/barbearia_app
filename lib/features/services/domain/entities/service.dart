import 'package:equatable/equatable.dart';

/// Entidade de Serviço
class Service extends Equatable {
  final int id;
  final String name;
  final String description;
  final int durationMinutes;
  final double price;
  final String? imageUrl;
  final bool isActive;

  const Service({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
    this.imageUrl,
    this.isActive = true,
  });

  /// Formata a duração em formato legível
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}min';
  }

  /// Formata o preço em formato BRL
  String get formattedPrice {
    return 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        durationMinutes,
        price,
        imageUrl,
        isActive,
      ];
}
