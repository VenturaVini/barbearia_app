import 'package:equatable/equatable.dart';

/// Eventos do ServiceBloc
abstract class ServiceEvent extends Equatable {
  const ServiceEvent();

  @override
  List<Object?> get props => [];
}

/// Carregar todos os serviços
class LoadServices extends ServiceEvent {}

/// Carregar serviço por ID
class LoadServiceById extends ServiceEvent {
  final int id;

  const LoadServiceById(this.id);

  @override
  List<Object?> get props => [id];
}

/// Criar novo serviço
class CreateService extends ServiceEvent {
  final String name;
  final String description;
  final int durationMinutes;
  final double price;
  final String? imageUrl;

  const CreateService({
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
        name,
        description,
        durationMinutes,
        price,
        imageUrl,
      ];
}

/// Atualizar serviço
class UpdateService extends ServiceEvent {
  final int id;
  final String? name;
  final String? description;
  final int? durationMinutes;
  final double? price;
  final String? imageUrl;
  final bool? isActive;

  const UpdateService({
    required this.id,
    this.name,
    this.description,
    this.durationMinutes,
    this.price,
    this.imageUrl,
    this.isActive,
  });

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

/// Deletar serviço
class DeleteService extends ServiceEvent {
  final int id;

  const DeleteService(this.id);

  @override
  List<Object?> get props => [id];
}
