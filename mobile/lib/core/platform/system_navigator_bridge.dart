import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Geri tuşu / "çıkış" akışında uygulamayı **kapatmak yerine** arka plana atar.
///
/// - **Android:** `MainActivity.moveTaskToBack(true)` çağrılır. Process yaşar,
///   kullanıcı uygulamayı recents'tan swipe'lamadıkça tekrar açılışta splash
///   gözükmeden kaldığı state ile devam eder.
/// - **iOS:** Apple uygulamanın kendini arka plana atmasına izin vermez,
///   bu yüzden no-op'tur. iOS'ta zaten "geri tuşu" yoktur; Home gesture
///   sistem tarafından doğru biçimde işlenir.
/// - **Diğer platformlar (Windows/Web/macOS/Linux):** Geliştirici/test
///   senaryoları için fallback olarak `SystemNavigator.pop()` çağrılır.
class SystemNavigatorBridge {
  SystemNavigatorBridge._();

  static const MethodChannel _channel =
      MethodChannel('com.aidatpanel.app/system');

  static Future<void> moveAppToBackground() async {
    if (kIsWeb) {
      return;
    }
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod<bool>('moveToBackground');
      } on PlatformException {
        // Native köprü yoksa son çare: uygulamayı kapat.
        await SystemNavigator.pop();
      }
      return;
    }
    if (Platform.isIOS) {
      return;
    }
    await SystemNavigator.pop();
  }
}
