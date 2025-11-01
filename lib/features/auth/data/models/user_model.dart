import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

/// Model de usuário (data layer)
@JsonSerializable()
class UserModel {
  final int id;
  final String username;
  final String email;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  final String? phone;
  @JsonKey(name: 'is_barber')
  final bool isBarber;
  @JsonKey(name: 'is_staff')
  final bool isStaff;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.isBarber = false,
    this.isStaff = false,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Converter para entidade
  User toEntity() {
    return User(
      id: id,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      isBarber: isBarber,
      isStaff: isStaff,
      avatarUrl: avatarUrl,
    );
  }

  /// Criar a partir de entidade
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      username: user.username,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      phone: user.phone,
      isBarber: user.isBarber,
      isStaff: user.isStaff,
      avatarUrl: user.avatarUrl,
    );
  }
}
