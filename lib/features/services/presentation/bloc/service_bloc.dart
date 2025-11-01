import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/service_repository.dart';
import '../../../../core/network/api_exception.dart';
import 'service_event.dart';
import 'service_state.dart';

/// BLoC de Serviços
class ServiceBloc extends Bloc<ServiceEvent, ServiceState> {
  final ServiceRepository _serviceRepository;

  ServiceBloc({required ServiceRepository serviceRepository})
      : _serviceRepository = serviceRepository,
        super(ServiceInitial()) {
    on<LoadServices>(_onLoadServices);
    on<LoadServiceById>(_onLoadServiceById);
    on<CreateService>(_onCreateService);
    on<UpdateService>(_onUpdateService);
    on<DeleteService>(_onDeleteService);
  }

  /// Carregar todos os serviços
  Future<void> _onLoadServices(
    LoadServices event,
    Emitter<ServiceState> emit,
  ) async {
    emit(ServiceLoading());

    try {
      final services = await _serviceRepository.getServices();
      emit(ServicesLoaded(services));
    } on ApiException catch (e) {
      emit(ServiceError(e.message));
    } catch (e) {
      emit(ServiceError('Erro ao carregar serviços: ${e.toString()}'));
    }
  }

  /// Carregar serviço por ID
  Future<void> _onLoadServiceById(
    LoadServiceById event,
    Emitter<ServiceState> emit,
  ) async {
    emit(ServiceLoading());

    try {
      final service = await _serviceRepository.getServiceById(event.id);
      emit(ServiceLoaded(service));
    } on ApiException catch (e) {
      emit(ServiceError(e.message));
    } catch (e) {
      emit(ServiceError('Erro ao carregar serviço: ${e.toString()}'));
    }
  }

  /// Criar novo serviço
  Future<void> _onCreateService(
    CreateService event,
    Emitter<ServiceState> emit,
  ) async {
    emit(ServiceLoading());

    try {
      final service = await _serviceRepository.createService(
        name: event.name,
        description: event.description,
        durationMinutes: event.durationMinutes,
        price: event.price,
        imageUrl: event.imageUrl,
      );
      emit(ServiceCreated(service));
    } on ApiException catch (e) {
      emit(ServiceError(e.message));
    } catch (e) {
      emit(ServiceError('Erro ao criar serviço: ${e.toString()}'));
    }
  }

  /// Atualizar serviço
  Future<void> _onUpdateService(
    UpdateService event,
    Emitter<ServiceState> emit,
  ) async {
    emit(ServiceLoading());

    try {
      final service = await _serviceRepository.updateService(
        id: event.id,
        name: event.name,
        description: event.description,
        durationMinutes: event.durationMinutes,
        price: event.price,
        imageUrl: event.imageUrl,
        isActive: event.isActive,
      );
      emit(ServiceUpdated(service));
    } on ApiException catch (e) {
      emit(ServiceError(e.message));
    } catch (e) {
      emit(ServiceError('Erro ao atualizar serviço: ${e.toString()}'));
    }
  }

  /// Deletar serviço
  Future<void> _onDeleteService(
    DeleteService event,
    Emitter<ServiceState> emit,
  ) async {
    emit(ServiceLoading());

    try {
      await _serviceRepository.deleteService(event.id);
      emit(ServiceDeleted());
    } on ApiException catch (e) {
      emit(ServiceError(e.message));
    } catch (e) {
      emit(ServiceError('Erro ao deletar serviço: ${e.toString()}'));
    }
  }
}
