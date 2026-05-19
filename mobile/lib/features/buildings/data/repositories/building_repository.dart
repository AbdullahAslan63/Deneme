import '../../domain/entities/building_entity.dart';

abstract class BuildingRepository {
  Future<List<BuildingEntity>> fetchBuildings();
  Future<BuildingEntity> createBuilding({
    required String name,
    required String address,
    required String city,
    int? totalFloors,
    int? apartmentsPerFloor,
    double? dueAmount,
    int? dueDay,
    String? currency,
  });
  Future<BuildingEntity> updateBuilding({
    required String id,
    String? name,
    String? address,
    String? city,
  });
  Future<void> deleteBuilding(String id);
}
