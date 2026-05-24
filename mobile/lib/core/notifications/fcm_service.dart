import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/api_exception.dart';
import '../storage/secure_storage.dart';
import 'fcm_platform.dart';
import 'fcm_token_remote_datasource.dart';
import 'notification_payload.dart';

typedef FcmNavigationHandler = void Function(NotificationPayload payload);

/// FCM izin, token kaydı ve mesaj dinleyicileri.
class FcmService {
  final FirebaseMessaging _messaging;
  final FcmTokenRemoteDataSource _tokenDataSource;
  final SecureStorage _secureStorage;

  bool _listenersAttached = false;

  FcmService({
    required FirebaseMessaging messaging,
    required FcmTokenRemoteDataSource tokenDataSource,
    required SecureStorage secureStorage,
  })  : _messaging = messaging,
        _tokenDataSource = tokenDataSource,
        _secureStorage = secureStorage;

  Future<void> attachListeners({
    required FcmNavigationHandler onOpenFromNotification,
    void Function(RemoteMessage message)? onForegroundMessage,
  }) async {
    if (_listenersAttached) return;
    _listenersAttached = true;

    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        debugPrint('[FCM foreground] ${message.notification?.title}');
      }
      onForegroundMessage?.call(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onForegroundMessage?.call(message);
      onOpenFromNotification(NotificationPayload.fromFcmData(message.data));
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      onForegroundMessage?.call(initial);
      onOpenFromNotification(NotificationPayload.fromFcmData(initial.data));
    }

    _messaging.onTokenRefresh.listen((token) async {
      if (kDebugMode) {
        debugPrint('[FCM] onTokenRefresh (${token.length} char)');
      }
      await _secureStorage.saveFcmToken(token);
      await _uploadIfPossible(token);
    });
  }

  Future<void> requestPermissions() async {
    if (!isFcmSupported) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      debugPrint('[FCM] izin durumu: ${settings.authorizationStatus}');
    }
  }

  /// Oturum açıkken token alır ve backend'e yükler.
  Future<void> syncTokenToBackend() async {
    if (!isFcmSupported) {
      if (kDebugMode) {
        debugPrint(
          '[FCM] Bu platformda push desteklenmiyor ($defaultTargetPlatform). '
          'Android emülatör/cihaz veya iOS kullanın.',
        );
      }
      return;
    }

    await requestPermissions();

    String? token;
    try {
      token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        await Future<void>.delayed(const Duration(seconds: 1));
        token = await _messaging.getToken();
      }
    } catch (e, st) {
      if (kDebugMode) {
        final msg = e.toString();
        if (msg.contains('MISSING_INSTANCEID_SERVICE') ||
            msg.contains('Google Play services')) {
          debugPrint(
            '[FCM] Google Play Services yok. Android Studio → Device Manager → '
            '"Play Store" simgesi olan x86_64 emülatör seçin veya fiziksel cihaz kullanın.',
          );
        } else {
          debugPrint('[FCM] getToken hata: $e\n$st');
        }
      }
      return;
    }

    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[FCM] Token alınamadı. Android: Google Play içeren emülatör/cihaz; '
          'iOS: gerçek cihaz veya push-capable simülatör + GoogleService-Info.plist.',
        );
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('[FCM] Cihaz token alındı (${token.length} karakter)');
    }

    final access = await _secureStorage.getToken();
    if (access == null || access.isEmpty) {
      if (kDebugMode) {
        debugPrint('[FCM] JWT yok — upload atlandı (önce giriş yapın).');
      }
      await _secureStorage.saveFcmToken(token);
      return;
    }

    final stored = await _secureStorage.getFcmToken();
    await _secureStorage.saveFcmToken(token);
    if (stored != token) {
      await _uploadIfPossible(token);
      return;
    }
    await _uploadIfPossible(token);
  }

  Future<void> _uploadIfPossible(String token) async {
    final access = await _secureStorage.getToken();
    if (access == null || access.isEmpty) {
      if (kDebugMode) {
        debugPrint('[FCM] Upload atlandı: access token yok.');
      }
      return;
    }

    try {
      await _tokenDataSource.uploadToken(token);
      if (kDebugMode) {
        debugPrint('[FCM] PUT /me/fcm-token başarılı.');
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[FCM] PUT /me/fcm-token başarısız (${e.statusCode}): ${e.message}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] PUT /me/fcm-token hata: $e');
      }
    }
  }
}
