/// Belge §2.2 (`RegisterData`): `user` alanı **string** (uuid).
/// Diğer alanlar `User` ile aynıdır (`token` dönmez).
class RegisterResponse {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String language;
  final String? apartmentId;

  RegisterResponse({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.language = 'tr',
    this.apartmentId,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      id: json['user'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      language: json['language'] as String? ?? 'tr',
      apartmentId: json['apartmentId'] as String?,
    );
  }
}
