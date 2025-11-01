// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceModel _$ServiceModelFromJson(Map<String, dynamic> json) => ServiceModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String,
  durationMinutes: (json['duration_minutes'] as num).toInt(),
  price: (json['price'] as num).toDouble(),
  imageUrl: json['image_url'] as String?,
  isActive: json['is_active'] as bool? ?? true,
);

Map<String, dynamic> _$ServiceModelToJson(ServiceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'duration_minutes': instance.durationMinutes,
      'price': instance.price,
      'image_url': instance.imageUrl,
      'is_active': instance.isActive,
    };
