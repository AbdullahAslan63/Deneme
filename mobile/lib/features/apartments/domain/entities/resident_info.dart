import 'package:equatable/equatable.dart';

/// Apartment listesinde her daire için backend'den gelen sakin bilgisi.
/// `null` ise daire boştur.
///
/// Belge §2.4: `GET /buildings/:id/apartments` her daire için
/// `resident: User | null` döner. Burada yalnızca UI'a faydalı
/// minimal alanlar tutulur (passwordHash gibi alanlar backend'de
/// budanır, mobile zaten okumaz).
class ResidentInfo extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String language;

  const ResidentInfo({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.language = 'tr',
  });

  @override
  List<Object?> get props => [id, name, email, phone, role, language];
}
