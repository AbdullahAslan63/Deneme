import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/invite_code_model.dart';

abstract class InviteCodeRemoteDataSource {
  Future<InviteCodeModel> generateInviteCode(String apartmentId);
}

class InviteCodeRemoteDataSourceImpl implements InviteCodeRemoteDataSource {
  final DioClient _dioClient;

  InviteCodeRemoteDataSourceImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  @override
  Future<InviteCodeModel> generateInviteCode(String apartmentId) async {
    final response = await _dioClient.post(
      ApiConstants.apartmentInviteCode(apartmentId),
    );
    return InviteCodeModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}
