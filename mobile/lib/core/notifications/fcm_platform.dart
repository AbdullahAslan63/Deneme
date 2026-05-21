import 'package:flutter/foundation.dart';

/// FCM yalnızca Android ve iOS'ta desteklenir (Linux/Windows/macOS/web'de token alınamaz).
bool get isFcmSupported {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    default:
      return false;
  }
}
