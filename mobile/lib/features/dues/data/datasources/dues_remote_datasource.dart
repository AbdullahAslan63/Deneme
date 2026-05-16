import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/due_model.dart';

abstract class DuesRemoteDataSource {
  /// Tur 5 / §10/3 — backend `dueController.getDuesByBuildingController`
  /// `month`, `year`, `status` query parametrelerini destekler. Tüm
  /// filtreler opsiyonel ve null gelirse sunucu tüm dues'u döner.
  Future<List<DueModel>> getBuildingDues(
    String buildingId, {
    int? month,
    int? year,
    String? status,
  });

  /// Belge §7: `GET /me/dues?month=&year=&status=` — sakin tarafında
  /// aynı filtre setini kabul eder.
  Future<List<DueModel>> getMyDues({
    int? month,
    int? year,
    String? status,
  });

  Future<DueModel> updateDueStatus({
    required String buildingId,
    required String dueId,
    required String status,
  });
  Future<void> updateBuildingDueAmount({
    required String buildingId,
    required double dueAmount,
    int? dueDay,
    String? currency,
    bool affectCurrent = false,
  });
}

class DuesRemoteDataSourceImpl implements DuesRemoteDataSource {
  final DioClient _dioClient;

  DuesRemoteDataSourceImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  Map<String, dynamic>? _buildDuesQuery({
    int? month,
    int? year,
    String? status,
  }) {
    final query = <String, dynamic>{};
    if (month != null) query['month'] = month;
    if (year != null) query['year'] = year;
    if (status != null) query['status'] = status;
    return query.isEmpty ? null : query;
  }

  @override
  Future<List<DueModel>> getBuildingDues(
    String buildingId, {
    int? month,
    int? year,
    String? status,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.buildingDues(buildingId),
      queryParameters: _buildDuesQuery(
        month: month,
        year: year,
        status: status,
      ),
    );
    final data = response.data['data'] as List;
    return data
        .map((json) => DueModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DueModel>> getMyDues({
    int? month,
    int? year,
    String? status,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.myDues,
      queryParameters: _buildDuesQuery(
        month: month,
        year: year,
        status: status,
      ),
    );
    final data = response.data['data'] as List;
    return data
        .map((json) => DueModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DueModel> updateDueStatus({
    required String buildingId,
    required String dueId,
    required String status,
  }) async {
    final response = await _dioClient.patch(
      ApiConstants.buildingDueStatus(buildingId, dueId),
      data: {'status': status},
    );
    return DueModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> updateBuildingDueAmount({
    required String buildingId,
    required double dueAmount,
    int? dueDay,
    String? currency,
    bool affectCurrent = false,
  }) async {
    await _dioClient.patch(
      ApiConstants.buildingDueAmount(buildingId),
      data: {
        'dueAmount': dueAmount,
        'dueDay': ?dueDay,
        if (currency != null && currency.isNotEmpty) 'currency': currency,
        'affectCurrent': affectCurrent,
      },
    );
  }
}
