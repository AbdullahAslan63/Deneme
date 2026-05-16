import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/secure_storage.dart';
import 'shared/widgets/friendly_error_screen.dart';
import 'shared/widgets/toast_overlay.dart';
import 'l10n/strings.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandlers();
  await initAppInfo();
  await initLocale();
  runApp(const ProviderScope(child: MyApp()));
}

/// - `ErrorWidget.builder`: build sırasında bir widget exception fırlatırsa
///   Flutter'ın varsayılan kıpkırmızı ekranı yerine kibarca kullanıcıya bildir.
/// - `FlutterError.onError`: framework içinde yakalanan hataları (build, layout
///   vb.) konsola düzgün bas; release'de Crashlytics'e bağlanabilir.
/// - `PlatformDispatcher.instance.onError`: zone dışı async uncaught error'ları
///   yakala (örn. bir Future error'ı kimse await etmediyse). `true` döndürmek
///   "ben hallettim, framework'e crash bildirme" demektir.
void _installGlobalErrorHandlers() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
    originalOnError?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('[PlatformDispatcher] Uncaught: $error\n$stack');
    }
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return FriendlyErrorScreen(details: details);
  };
}

Future<void> initAppInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();
  AppConstants.appVersion = packageInfo.version;
}

Future<void> initLocale() async {
  final storage = SecureStorage();
  final savedLanguage = await storage.getLanguage();
  if (savedLanguage != null) {
    LocaleSettings.setLocale(
      AppLocaleUtils.parseLocaleParts(languageCode: savedLanguage),
    );
  } else {
    LocaleSettings.setLocale(AppLocale.tr);
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return TranslationProvider(
      child: MaterialApp.router(
        title: 'AidatPanel',
        theme: AppTheme.lightTheme(),
        routerConfig: router,
        locale: LocaleSettings.currentLocale.flutterLocale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocaleUtils.supportedLocales,
        builder: (context, child) {
          return ToastOverlay(child: child ?? const SizedBox.shrink());
        },
      ),
    );
  }
}
