import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'login_response.g.dart';

/// Response de login
@JsonSerializable()
class LoginResponse {
  final String access;
  final String refresh;
  final UserModel user;

  LoginResponse({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}
