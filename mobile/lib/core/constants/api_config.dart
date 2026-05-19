/// API taban adresi.
///
/// Yerel backend (emülatör): `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4200`
/// Windows masaüstü: `--dart-define=API_BASE_URL=http://127.0.0.1:4200`
/// Prod: tanımsız → [defaultBaseUrl]
class ApiConfig {
  static const String defaultBaseUrl = 'https://api.aidatpanel.com';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  static bool get isLocal =>
      baseUrl.contains('127.0.0.1') || baseUrl.contains('10.0.2.2');
}
