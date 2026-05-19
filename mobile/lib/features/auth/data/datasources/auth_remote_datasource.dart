import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/join_request.dart';
import '../models/join_response.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(LoginRequest request);
  Future<RegisterResponse> register(RegisterRequest request);
  Future<JoinResponse> join(JoinRequest request);
  Future<String> refreshToken(String refreshToken);

  /// Sunucuya `POST /auth/logout` (Bearer) atar.
  /// Backend `refreshTokenVersion`'ı artırarak mevcut refresh token'ı geçersiz kılar.
  /// Belge §3 ve "kontrol listesi" madde 4 zorunlu kılar.
  Future<void> logout();

  /// Tur 5 / §10/6 — `POST /auth/forgot-password` body `{ email }`.
  /// Backend her zaman 200 döner (enumeration leak yok); kod sadece kayıtlı
  /// e-postalara Resend ile gönderilir.
  Future<void> forgotPassword({required String email});

  /// `POST /auth/reset-password` body `{ token, password }`.
  /// Token 6 karakter alfabesi `23456789ABCDEFGHJKLMNPQRSTUVWXYZ` (sunucu
  /// trim + büyük harfe çevirir). Geçersiz/expired token → 400.
  Future<void> resetPassword({
    required String token,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSourceImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _dioClient.post(
      ApiConstants.login,
      data: request.toJson(),
    );
    return LoginResponse.fromJson(response.data['data']);
  }

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    final response = await _dioClient.post(
      ApiConstants.register,
      data: request.toJson(),
    );
    return RegisterResponse.fromJson(response.data['data']);
  }

  @override
  Future<JoinResponse> join(JoinRequest request) async {
    final response = await _dioClient.post(
      ApiConstants.join,
      data: request.toJson(),
    );
    return JoinResponse.fromJson(response.data['data']);
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    final response = await _dioClient.post(
      ApiConstants.refresh,
      data: {'refreshToken': refreshToken},
    );
    final raw = response.data;
    final Map<String, dynamic> payload = raw is Map && raw['data'] != null
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return payload['accessToken'] as String;
  }

  @override
  Future<void> logout() async {
    await _dioClient.post(ApiConstants.logout);
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _dioClient.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _dioClient.post(
      ApiConstants.resetPassword,
      data: {'token': token, 'password': password},
    );
  }
}
