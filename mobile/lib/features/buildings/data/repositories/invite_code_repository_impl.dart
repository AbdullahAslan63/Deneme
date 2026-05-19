import '../../../../core/network/api_exception.dart';
import '../datasources/invite_code_remote_datasource.dart';
import '../models/invite_code_model.dart';
import 'invite_code_repository.dart';

class InviteCodeRepositoryImpl implements InviteCodeRepository {
  final InviteCodeRemoteDataSource _remoteDataSource;

  InviteCodeRepositoryImpl(
      {required InviteCodeRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<InviteCodeModel> generateInviteCode(String apartmentId) async {
    try {
      return await _remoteDataSource.generateInviteCode(apartmentId);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Davet kodu oluşturulurken hata oluştu: $e');
    }
  }
}
