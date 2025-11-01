import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/service.dart';
import '../models/service_model.dart';

/// Repositório de Serviços
class ServiceRepository {
  /// Listar todos os serviços ativos
  Future<List<Service>> getServices() async {
    final response = await DioClient.get(
      ApiConstants.services,
    );

    final List<dynamic> data = response.data['results'] ?? response.data;
    return data.map((json) => ServiceModel.fromJson(json).toEntity()).toList();
  }

  /// Buscar serviço por ID
  Future<Service> getServiceById(int id) async {
    final response = await DioClient.get(
      '${ApiConstants.services}$id/',
    );

    return ServiceModel.fromJson(response.data).toEntity();
  }

  /// Criar novo serviço (apenas Admin)
  Future<Service> createService({
    required String name,
    required String description,
    required int durationMinutes,
    required double price,
    String? imageUrl,
  }) async {
    final response = await DioClient.post(
      ApiConstants.services,
      data: {
        'name': name,
        'description': description,
        'duration_minutes': durationMinutes,
        'price': price,
        if (imageUrl != null) 'image_url': imageUrl,
      },
    );

    return ServiceModel.fromJson(response.data).toEntity();
  }

  /// Atualizar serviço (apenas Admin)
  Future<Service> updateService({
    required int id,
    String? name,
    String? description,
    int? durationMinutes,
    double? price,
    String? imageUrl,
    bool? isActive,
  }) async {
    final response = await DioClient.patch(
      '${ApiConstants.services}$id/',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (price != null) 'price': price,
        if (imageUrl != null) 'image_url': imageUrl,
        if (isActive != null) 'is_active': isActive,
      },
    );

    return ServiceModel.fromJson(response.data).toEntity();
  }

  /// Deletar serviço (apenas Admin)
  Future<void> deleteService(int id) async {
    await DioClient.delete(
      '${ApiConstants.services}$id/',
    );
  }
}
