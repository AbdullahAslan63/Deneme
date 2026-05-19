import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/strings.g.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final localeProvider = StateProvider<AppLocale>((ref) {
  return LocaleSettings.currentLocale;
});

Future<void> changeLocale(WidgetRef ref, AppLocale locale) async {
  LocaleSettings.setLocale(locale);
  ref.read(localeProvider.notifier).state = locale;
  await ref.read(secureStorageProvider).saveLanguage(locale.languageCode);
}
