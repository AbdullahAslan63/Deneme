import '../../domain/entities/resident_info.dart';

class ResidentModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String language;

  ResidentModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.language = 'tr',
  });

  factory ResidentModel.fromJson(Map<String, dynamic> json) {
    return ResidentModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'RESIDENT',
      language: json['language'] as String? ?? 'tr',
    );
  }

  ResidentInfo toEntity() {
    return ResidentInfo(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      language: language,
    );
  }
}
