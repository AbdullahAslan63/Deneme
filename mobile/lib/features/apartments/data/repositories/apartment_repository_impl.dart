import '../../../../core/network/api_exception.dart';
import '../../domain/entities/apartment_entity.dart';
import '../datasources/apartment_remote_datasource.dart';
import 'apartment_repository.dart';

class ApartmentRepositoryImpl implements ApartmentRepository {
  final ApartmentRemoteDataSource _remoteDataSource;

  ApartmentRepositoryImpl({required ApartmentRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<ApartmentEntity>> fetchApartments(String buildingId) async {
    try {
      final models = await _remoteDataSource.fetchApartments(buildingId);
      return models.map((m) => m.toEntity()).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Daireler yüklenirken hata oluştu: $e');
    }
  }

  @override
  Future<ApartmentEntity> createApartment({
    required String buildingId,
    required String number,
    int? floor,
  }) async {
    try {
      final model = await _remoteDataSource.createApartment(
        buildingId: buildingId,
        number: number,
        floor: floor,
      );
      return model.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Daire eklenirken hata oluştu: $e');
    }
  }

  @override
  Future<ApartmentEntity> updateApartment({
    required String buildingId,
    required String id,
    String? number,
    int? floor,
  }) async {
    try {
      final model = await _remoteDataSource.updateApartment(
        buildingId: buildingId,
        id: id,
        number: number,
        floor: floor,
      );
      return model.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Daire güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteApartment({
    required String buildingId,
    required String id,
  }) async {
    try {
      await _remoteDataSource.deleteApartment(buildingId: buildingId, id: id);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Daire silinirken hata oluştu: $e');
    }
  }

  @override
  Future<ApartmentEntity> removeResident({
    required String buildingId,
    required String apartmentId,
  }) async {
    try {
      final model = await _remoteDataSource.removeResident(
        buildingId: buildingId,
        apartmentId: apartmentId,
      );
      return model.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Sakin çıkarılırken hata oluştu: $e');
    }
  }
}
