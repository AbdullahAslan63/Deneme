import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

/// Tur 5 / §10/4-5 — Backend `meControllers` (commit 8cc2152) tarafından
/// açılan kullanıcı profil ve hesap kapama uçları.
abstract class ProfileRemoteDataSource {
  /// `PUT /api/v1/me/password` body `{ currentPassword, newPassword }`.
  /// Backend başarıdan sonra `refreshTokenVersion++` yapıyor → mevcut
  /// refresh token geçersizleşir, sonraki 401'de mobile otomatik logout.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// `DELETE /api/v1/me` — KVKK soft delete.
  /// Backend yanıtları:
  ///  - 200: hesap kapatıldı (PII maskelendi, refreshTokenVersion++)
  ///  - 409: yöneticide bina var → "Önce binaları silin/devredin"
  Future<void> deleteAccount();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioClient _dioClient;

  ProfileRemoteDataSourceImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dioClient.put(
      ApiConstants.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  @override
  Future<void> deleteAccount() async {
    await _dioClient.delete(ApiConstants.profile);
  }
}
