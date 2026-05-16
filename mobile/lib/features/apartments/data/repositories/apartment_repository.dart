import '../../domain/entities/apartment_entity.dart';

abstract class ApartmentRepository {
  Future<List<ApartmentEntity>> fetchApartments(String buildingId);
  Future<ApartmentEntity> createApartment({
    required String buildingId,
    required String number,
    int? floor,
  });
  Future<ApartmentEntity> updateApartment({
    required String buildingId,
    required String id,
    String? number,
    int? floor,
  });
  Future<void> deleteApartment({
    required String buildingId,
    required String id,
  });

  /// Tur 5 / §3.1 — Daireden sakini çıkar (hesap silinmez).
  /// Backend güncel apartment'ı (resident: null) döner.
  Future<ApartmentEntity> removeResident({
    required String buildingId,
    required String apartmentId,
  });
}
