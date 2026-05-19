import '../../../../core/network/api_exception.dart';
import '../datasources/profile_remote_datasource.dart';
import 'profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl({required ProfileRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Şifre değiştirilemedi: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Hesap kapatılamadı: $e');
    }
  }
}
