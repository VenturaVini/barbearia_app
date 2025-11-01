import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/service.dart';

part 'service_model.g.dart';

/// Model de Serviço
@JsonSerializable()
class ServiceModel {
  final int id;
  final String name;
  final String description;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  final double price;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'is_active')
  final bool isActive;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
    this.imageUrl,
    this.isActive = true,
  });

  /// Converte JSON para Model
  factory ServiceModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceModelFromJson(json);

  /// Converte Model para JSON
  Map<String, dynamic> toJson() => _$ServiceModelToJson(this);

  /// Converte Model para Entity
  Service toEntity() {
    return Service(
      id: id,
      name: name,
      description: description,
      durationMinutes: durationMinutes,
      price: price,
      imageUrl: imageUrl,
      isActive: isActive,
    );
  }

  /// Converte Entity para Model
  factory ServiceModel.fromEntity(Service service) {
    return ServiceModel(
      id: service.id,
      name: service.name,
      description: service.description,
      durationMinutes: service.durationMinutes,
      price: service.price,
      imageUrl: service.imageUrl,
      isActive: service.isActive,
    );
  }
}
