import 'package:equatable/equatable.dart';
import '../../domain/entities/service.dart';

/// Estados do ServiceBloc
abstract class ServiceState extends Equatable {
  const ServiceState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ServiceInitial extends ServiceState {}

/// Carregando
class ServiceLoading extends ServiceState {}

/// Serviços carregados
class ServicesLoaded extends ServiceState {
  final List<Service> services;

  const ServicesLoaded(this.services);

  @override
  List<Object?> get props => [services];
}

/// Serviço único carregado
class ServiceLoaded extends ServiceState {
  final Service service;

  const ServiceLoaded(this.service);

  @override
  List<Object?> get props => [service];
}

/// Serviço criado com sucesso
class ServiceCreated extends ServiceState {
  final Service service;

  const ServiceCreated(this.service);

  @override
  List<Object?> get props => [service];
}

/// Serviço atualizado com sucesso
class ServiceUpdated extends ServiceState {
  final Service service;

  const ServiceUpdated(this.service);

  @override
  List<Object?> get props => [service];
}

/// Serviço deletado com sucesso
class ServiceDeleted extends ServiceState {}

/// Erro
class ServiceError extends ServiceState {
  final String message;

  const ServiceError(this.message);

  @override
  List<Object?> get props => [message];
}
