import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fcm_provider.dart';
import 'fcm_service.dart';

/// Giriş / join / oturum restore sonrası token'ı backend'e gönderir.
///
/// [ref] yalnızca senkron okuma için kullanılır; gecikmeden sonra widget
/// dispose olabileceği için servis örneği önceden alınır.
Future<void> syncFcmAfterAuth(WidgetRef ref) async {
  final FcmService fcm = ref.read(fcmServiceProvider);
  await syncFcmWithService(fcm);
}

/// Widget dışından (ör. kalıcı scope) aynı akış.
Future<void> syncFcmWithService(FcmService fcm) async {
  await Future<void>.delayed(const Duration(milliseconds: 500));
  await fcm.syncTokenToBackend();
}
