import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> saveUser(String user) async {
    await _storage.write(key: AppConstants.userKey, value: user);
  }

  Future<String?> getUser() async {
    return await _storage.read(key: AppConstants.userKey);
  }

  Future<void> saveLanguage(String language) async {
    await _storage.write(key: AppConstants.languageKey, value: language);
  }

  Future<String?> getLanguage() async {
    return await _storage.read(key: AppConstants.languageKey);
  }

  Future<void> saveFcmToken(String token) async {
    await _storage.write(key: AppConstants.fcmTokenKey, value: token);
  }

  Future<String?> getFcmToken() async {
    return await _storage.read(key: AppConstants.fcmTokenKey);
  }

  Future<void> saveTokenExpiry(DateTime expiry) async {
    await _storage.write(
      key: AppConstants.tokenExpiryKey,
      value: expiry.millisecondsSinceEpoch.toString(),
    );
  }

  Future<DateTime?> getTokenExpiry() async {
    final value = await _storage.read(key: AppConstants.tokenExpiryKey);
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(value));
  }

  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  Future<void> clearAuth() async {
    final language = await getLanguage();
    await _storage.deleteAll();
    if (language != null) await saveLanguage(language);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
