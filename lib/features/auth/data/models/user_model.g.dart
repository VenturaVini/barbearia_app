// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  email: json['email'] as String,
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  phone: json['phone'] as String?,
  isBarber: json['is_barber'] as bool? ?? false,
  isStaff: json['is_staff'] as bool? ?? false,
  avatarUrl: json['avatar_url'] as String?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'phone': instance.phone,
  'is_barber': instance.isBarber,
  'is_staff': instance.isStaff,
  'avatar_url': instance.avatarUrl,
};
