import '../../../../core/network/api_exception.dart';
import '../../domain/entities/building_entity.dart';
import '../datasources/building_remote_datasource.dart';
import 'building_repository.dart';

class BuildingRepositoryImpl implements BuildingRepository {
  final BuildingRemoteDataSource _remoteDataSource;

  BuildingRepositoryImpl({required BuildingRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<BuildingEntity>> fetchBuildings() async {
    try {
      final models = await _remoteDataSource.fetchBuildings();
      return models.map((m) => m.toEntity()).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Binalar yüklenirken hata oluştu: $e');
    }
  }

  @override
  Future<BuildingEntity> createBuilding({
    required String name,
    required String address,
    required String city,
    int? totalFloors,
    int? apartmentsPerFloor,
    double? dueAmount,
    int? dueDay,
    String? currency,
  }) async {
    try {
      final model = await _remoteDataSource.createBuilding(
        name: name,
        address: address,
        city: city,
        totalFloors: totalFloors,
        apartmentsPerFloor: apartmentsPerFloor,
        dueAmount: dueAmount,
        dueDay: dueDay,
        currency: currency,
      );
      return model.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Bina eklenirken hata oluştu: $e');
    }
  }

  @override
  Future<BuildingEntity> updateBuilding({
    required String id,
    String? name,
    String? address,
    String? city,
  }) async {
    try {
      final model = await _remoteDataSource.updateBuilding(
        id: id,
        name: name,
        address: address,
        city: city,
      );
      return model.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Bina güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteBuilding(String id) async {
    try {
      await _remoteDataSource.deleteBuilding(id);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Bina silinirken hata oluştu: $e');
    }
  }
}
