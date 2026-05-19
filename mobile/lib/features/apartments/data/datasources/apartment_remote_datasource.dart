import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/apartment_model.dart';

abstract class ApartmentRemoteDataSource {
  Future<List<ApartmentModel>> fetchApartments(String buildingId);
  Future<ApartmentModel> createApartment({
    required String buildingId,
    required String number,
    int? floor,
  });
  Future<ApartmentModel> updateApartment({
    required String buildingId,
    required String id,
    String? number,
    int? floor,
  });
  Future<void> deleteApartment({
    required String buildingId,
    required String id,
  });

  /// Tur 5 / §3.1 — Manager bu daireden sakini çıkarır.
  /// Sakin hesabı silinmez, sadece `User.apartmentId` ve
  /// `Apartment.residentId` null'a çekilir; aidat geçmişi korunur.
  Future<ApartmentModel> removeResident({
    required String buildingId,
    required String apartmentId,
  });
}

class ApartmentRemoteDataSourceImpl implements ApartmentRemoteDataSource {
  final DioClient _dioClient;

  ApartmentRemoteDataSourceImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  @override
  Future<List<ApartmentModel>> fetchApartments(String buildingId) async {
    final response =
        await _dioClient.get(ApiConstants.buildingApartments(buildingId));
    final data = response.data['data'] as List;
    return data
        .map((json) => ApartmentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ApartmentModel> createApartment({
    required String buildingId,
    required String number,
    int? floor,
  }) async {
    final body = <String, dynamic>{
      'number': number,
      'floor': ?floor,
    };
    final response = await _dioClient.post(
      ApiConstants.buildingApartments(buildingId),
      data: body,
    );
    return ApartmentModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<ApartmentModel> updateApartment({
    required String buildingId,
    required String id,
    String? number,
    int? floor,
  }) async {
    final body = <String, dynamic>{
      'number': ?number,
      'floor': ?floor,
    };
    final response = await _dioClient.put(
      '${ApiConstants.buildingApartments(buildingId)}/$id',
      data: body,
    );
    return ApartmentModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteApartment({
    required String buildingId,
    required String id,
  }) async {
    await _dioClient
        .delete('${ApiConstants.buildingApartments(buildingId)}/$id');
  }

  @override
  Future<ApartmentModel> removeResident({
    required String buildingId,
    required String apartmentId,
  }) async {
    final response = await _dioClient
        .delete(ApiConstants.apartmentResident(buildingId, apartmentId));
    return ApartmentModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}
