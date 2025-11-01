import 'package:equatable/equatable.dart';

/// Entidade de usuário (domain layer)
class User extends Equatable {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final bool isBarber;
  final bool isStaff;
  final String? avatarUrl;

  const User({
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

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    return username;
  }

  String get userType {
    if (isStaff) return 'admin';
    if (isBarber) return 'barber';
    return 'client';
  }

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        firstName,
        lastName,
        phone,
        isBarber,
        isStaff,
        avatarUrl,
      ];
}
