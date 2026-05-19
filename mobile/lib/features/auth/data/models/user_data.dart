import '../../../auth/domain/entities/user_entity.dart';

class UserData {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final String language;
  final String? apartmentId;

  UserData({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.language = 'tr',
    this.apartmentId,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      language: json['language'] as String? ?? 'tr',
      apartmentId: json['apartmentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'language': language,
      'apartmentId': apartmentId,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      name: name,
      phone: phone,
      role: role == 'MANAGER' ? UserRole.manager : UserRole.resident,
      language: language,
      apartmentId: apartmentId,
    );
  }
}
