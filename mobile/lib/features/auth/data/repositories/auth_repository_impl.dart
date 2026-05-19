import 'dart:convert';

import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/join_request.dart';
import '../models/user_data.dart';

DateTime _parseJwtExpiry(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return DateTime.now().add(const Duration(minutes: 15));
    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    final data = jsonDecode(decoded) as Map<String, dynamic>;
    final exp = data['exp'] as int?;
    if (exp == null) return DateTime.now().add(const Duration(minutes: 15));
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  } catch (_) {
    return DateTime.now().add(const Duration(minutes: 15));
  }
}

abstract class AuthRepository {
  /// `identifier` email **veya** telefon olabilir (Belge §3).
  Future<UserEntity> login(String identifier, String password);
  Future<void> register(
    String email,
    String password,
    String name,
    String? phone,
  );
  Future<UserEntity> join(
    String inviteCode,
    String email,
    String password,
    String name,
    String? phone,
  );
  Future<void> logout();

  /// Tur 5 / §10/6 — Şifremi unuttum akışı.
  /// Backend her zaman 200 döner; UI kullanıcıya "kod gönderildi" mesajı
  /// gösterip reset ekranına geçirir (enumeration leak korumalı).
  Future<void> forgotPassword(String email);

  /// 6 karakter token + yeni şifre. Geçersiz/expired token → ApiException.
  Future<void> resetPassword(String token, String password);

  Future<UserEntity?> getStoredUser();

  /// Uygulama açılışında çağrılır. SecureStorage'daki kullanıcıyı geri yükler.
  /// - Token geçerliyse direkt user döner.
  /// - Token süresi dolmuşsa refresh dener; başarılıysa user döner.
  /// - Refresh 401/403 alırsa storage temizlenir, null döner.
  /// - Ağ hatasında stale token'la user döndürür (interceptor sonra yeniler).
  Future<UserEntity?> restoreSession();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorage _secureStorage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorage secureStorage,
  }) : _remoteDataSource = remoteDataSource,
       _secureStorage = secureStorage;

  @override
  Future<UserEntity> login(String identifier, String password) async {
    try {
      final request =
          LoginRequest(identifier: identifier, password: password);
      final response = await _remoteDataSource.login(request);

      await _secureStorage.saveToken(response.accessToken);
      await _secureStorage.saveRefreshToken(response.refreshToken);
      await _secureStorage.saveUser(jsonEncode(response.user.toJson()));
      await _secureStorage.saveTokenExpiry(_parseJwtExpiry(response.accessToken));

      return response.user.toEntity();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(message: 'Giriş sırasında bir hata oluştu');
    }
  }

  @override
  Future<void> register(
    String email,
    String password,
    String name,
    String? phone,
  ) async {
    try {
      final request = RegisterRequest(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      await _remoteDataSource.register(request);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(message: 'Kayıt sırasında bir hata oluştu');
    }
  }

  @override
  Future<UserEntity> join(
    String inviteCode,
    String email,
    String password,
    String name,
    String? phone,
  ) async {
    try {
      final request = JoinRequest(
        inviteCode: inviteCode,
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      final response = await _remoteDataSource.join(request);

      await _secureStorage.saveToken(response.accessToken);
      await _secureStorage.saveRefreshToken(response.refreshToken);
      await _secureStorage.saveUser(jsonEncode(response.user.toJson()));
      await _secureStorage.saveTokenExpiry(_parseJwtExpiry(response.accessToken));

      return response.user.toEntity();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(message: 'Katılım sırasında bir hata oluştu');
    }
  }

  @override
  Future<void> logout() async {
    // Belge §3: çıkışta sunucuya POST /auth/logout zorunlu, ardından
    // yerel token silinir. Sunucu hata verse bile (örn. network) kullanıcı
    // yine "çıkmış" olmalı; yoksa donar. Bu yüzden hata yutulur.
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Sunucuya ulaşılamasa bile yerel temizlik garantili.
    }
    await _secureStorage.clearAuth();
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _remoteDataSource.forgotPassword(email: email);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(message: 'İstek gönderilemedi, lütfen tekrar deneyin');
    }
  }

  @override
  Future<void> resetPassword(String token, String password) async {
    try {
      await _remoteDataSource.resetPassword(
        token: token,
        password: password,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(message: 'Şifre sıfırlanamadı, lütfen tekrar deneyin');
    }
  }

  @override
  Future<UserEntity?> getStoredUser() async {
    final userJson = await _secureStorage.getUser();
    if (userJson == null) return null;

    try {
      final userData = UserData.fromJson(jsonDecode(userJson));
      return userData.toEntity();
    } catch (_) {
      await _secureStorage.clearAll();
      return null;
    }
  }

  @override
  Future<UserEntity?> restoreSession() async {
    final user = await getStoredUser();
    if (user == null) return null;

    final accessToken = await _secureStorage.getToken();
    if (accessToken == null) {
      await _secureStorage.clearAuth();
      return null;
    }

    final isExpired = await _secureStorage.isTokenExpired();
    if (!isExpired) return user;

    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) {
      await _secureStorage.clearAuth();
      return null;
    }

    try {
      final newAccessToken =
          await _remoteDataSource.refreshToken(refreshToken);
      await _secureStorage.saveToken(newAccessToken);
      await _secureStorage.saveTokenExpiry(_parseJwtExpiry(newAccessToken));
      return user;
    } on ApiException catch (e) {
      // Refresh token gerçekten geçersiz olduğunda oturumu kapat.
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _secureStorage.clearAuth();
        return null;
      }
      // Ağ/timeout/sunucu hatası: kullanıcıyı oturumda tut, ilk istek
      // sırasında interceptor tekrar refresh deneyecek.
      return user;
    } catch (_) {
      return user;
    }
  }
}
