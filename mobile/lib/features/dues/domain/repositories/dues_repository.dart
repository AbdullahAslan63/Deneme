import '../entities/due_entity.dart';

abstract class DuesRepository {
  /// Tur 5 / §10/3 — server-side filtreleme.
  /// Tüm parametreler opsiyonel; null geçilirse sunucu tüm dues'u döner.
  Future<List<DueEntity>> getBuildingDues(
    String buildingId, {
    int? month,
    int? year,
    DueStatus? status,
  });

  Future<List<DueEntity>> getMyDues({
    int? month,
    int? year,
    DueStatus? status,
  });

  Future<DueEntity> updateDueStatus({
    required String buildingId,
    required String dueId,
    required DueStatus status,
  });
  Future<void> updateBuildingDueAmount({
    required String buildingId,
    required double dueAmount,
    int? dueDay,
    String? currency,
    bool affectCurrent = false,
  });
}
