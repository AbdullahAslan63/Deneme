/// Dev preview entry point — sunucu yokken UI'ı test etmek için.
///
/// Çalıştırma:
///   flutter run -t lib/main_dev.dart -d emulator-5554
///
/// Production akışını bozmadan (main.dart aynen kalır) ProviderScope.overrides
/// ile şu repository'ler in-memory mock'lara değiştirilir:
///   - authRepositoryProvider       → MockAuthRepository (otomatik manager girişi)
///   - buildingRepositoryProvider   → MockBuildingRepository (2 hazır bina)
///   - apartmentRepositoryProvider  → MockApartmentRepository (her binada birkaç daire)
///   - duesRepositoryProvider       → MockDuesRepository (boş, sadece UI gezmesi için)
///   - profileRepositoryProvider    → MockProfileRepository (şifre Eski123. , reset kodu ABCDEF)
///
/// Splash → restoreSession sahte manager kullanıcı döner → router otomatik
/// olarak `/manager-dashboard` rotasına yönlendirir. Login/register ekranlarına
/// hiç uğramazsın.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/secure_storage.dart';
import 'dev/dev_mocks.dart';
import 'features/apartments/data/apartments_store.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/buildings/data/buildings_store.dart';
import 'features/dues/presentation/providers/dues_provider.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'shared/widgets/friendly_error_screen.dart';
import 'shared/widgets/toast_overlay.dart';
import 'l10n/strings.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandlers();
  await _initAppInfo();
  await _initLocale();

  // Apartment repository'yi önce kur — building repository FK kontrolü için
  // ona referans alıyor. (Mock dünya: bina silmek istendiğinde "daire varsa
  // hata" simülasyonu için bağlı)
  final mockApartments = MockApartmentRepository();
  final mockBuildings = MockBuildingRepository(mockApartments);
  final mockAuth = MockAuthRepository();
  final mockDues = MockDuesRepository();
  final mockProfile = MockProfileRepository();

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuth),
        buildingRepositoryProvider.overrideWithValue(mockBuildings),
        apartmentRepositoryProvider.overrideWithValue(mockApartments),
        duesRepositoryProvider.overrideWithValue(mockDues),
        profileRepositoryProvider.overrideWithValue(mockProfile),
      ],
      child: const _DevBanner(child: _DevApp()),
    ),
  );
}

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
      debugPrint('[DEV] Uncaught: $error\n$stack');
    }
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return FriendlyErrorScreen(details: details);
  };
}

Future<void> _initAppInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();
  AppConstants.appVersion = packageInfo.version;
}

Future<void> _initLocale() async {
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

class _DevApp extends ConsumerWidget {
  const _DevApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return TranslationProvider(
      child: MaterialApp.router(
        title: 'AidatPanel (DEV)',
        theme: AppTheme.lightTheme(),
        debugShowCheckedModeBanner: false,
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

/// Ekranın sağ üstüne küçük "DEV PREVIEW" rozeti — production build'den
/// ayırt edebilmek için.
class _DevBanner extends StatelessWidget {
  final Widget child;
  const _DevBanner({required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          const Positioned(
            top: 0,
            right: 0,
            child: IgnorePointer(
              child: _DevTag(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevTag extends StatelessWidget {
  const _DevTag();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(top: 4, right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.deepOrange,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'DEV',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
