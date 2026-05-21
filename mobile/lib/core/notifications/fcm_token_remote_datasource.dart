import '../constants/api_constants.dart';
import '../network/dio_client.dart';

/// Backend `PUT /api/v1/me/fcm-token` — yalnızca JWT ile çağrılır.
class FcmTokenRemoteDataSource {
  final DioClient _dioClient;

  FcmTokenRemoteDataSource({required DioClient dioClient}) : _dioClient = dioClient;

  Future<void> uploadToken(String fcmToken) async {
    await _dioClient.put(
      ApiConstants.fcmToken,
      data: {'fcmToken': fcmToken},
    );
  }
}
