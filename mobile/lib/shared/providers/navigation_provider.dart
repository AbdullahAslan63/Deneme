import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manager dashboard için tab index state provider
/// TabController ile sync edilir, BottomNavigationBar'ın currentIndex'ini yönetir
final managerTabIndexProvider = StateProvider<int>((ref) => 0);

/// Resident dashboard için tab index state provider
final residentTabIndexProvider = StateProvider<int>((ref) => 0);

/// Manager dashboard tab index'ini sıfırlar (logout/login için)
void resetManagerTabIndex(WidgetRef ref) {
  ref.read(managerTabIndexProvider.notifier).state = 0;
}

/// Resident dashboard tab index'ini sıfırlar (logout/login için)
void resetResidentTabIndex(WidgetRef ref) {
  ref.read(residentTabIndexProvider.notifier).state = 0;
}
