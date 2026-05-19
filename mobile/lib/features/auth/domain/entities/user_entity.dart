import 'package:equatable/equatable.dart';

enum UserRole { manager, resident }

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;
  final String? fcmToken;
  final String language;

  /// Sakin için bağlı olduğu daire id'si. Yönetici hesaplarında null'dır.
  /// Belge §2.1: `User.apartmentId` (null veya uuid).
  final String? apartmentId;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.fcmToken,
    this.language = 'tr',
    this.apartmentId,
  });

  @override
  List<Object?> get props =>
      [id, email, name, phone, role, fcmToken, language, apartmentId];
}
