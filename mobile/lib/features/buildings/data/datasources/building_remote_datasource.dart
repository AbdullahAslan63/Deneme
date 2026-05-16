import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/building_model.dart';

abstract class BuildingRemoteDataSource {
  Future<List<BuildingModel>> fetchBuildings();
  Future<BuildingModel> createBuilding({
    required String name,
    required String address,
    required String city,
    int? totalFloors,
    int? apartmentsPerFloor,
    double? dueAmount,
    int? dueDay,
    String? currency,
  });
  Future<BuildingModel> updateBuilding({
    required String id,
    String? name,
    String? address,
    String? city,
  });
  Future<void> deleteBuilding(String id);
}

class BuildingRemoteDataSourceImpl implements BuildingRemoteDataSource {
  final DioClient _dioClient;

  BuildingRemoteDataSourceImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  @override
  Future<List<BuildingModel>> fetchBuildings() async {
    final response = await _dioClient.get(ApiConstants.buildings);
    final data = response.data['data'] as List;
    return data
        .map((json) => BuildingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BuildingModel> createBuilding({
    required String name,
    required String address,
    required String city,
    int? totalFloors,
    int? apartmentsPerFloor,
    double? dueAmount,
    int? dueDay,
    String? currency,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'address': address,
      'city': city,
      'totalFloors': ?totalFloors,
      'apartmentsPerFloor': ?apartmentsPerFloor,
      'dueAmount': ?dueAmount,
      'dueDay': ?dueDay,
      'currency': ?currency,
    };
    final response = await _dioClient.post(ApiConstants.buildings, data: body);
    return BuildingModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<BuildingModel> updateBuilding({
    required String id,
    String? name,
    String? address,
    String? city,
  }) async {
    final body = <String, dynamic>{
      'name': ?name,
      'address': ?address,
      'city': ?city,
    };
    final response =
        await _dioClient.put(ApiConstants.buildingDetail(id), data: body);
    return BuildingModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteBuilding(String id) async {
    await _dioClient.delete(ApiConstants.buildingDetail(id));
  }
}
