import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../router/app_router.dart';
import 'fcm_provider.dart';
import 'fcm_sync.dart' show syncFcmWithService;
import 'notification_payload.dart';

/// FCM dinleyicileri + oturum açılınca token senkronu + bildirimden navigasyon.
class FcmScope extends ConsumerStatefulWidget {
  final Widget child;

  const FcmScope({super.key, required this.child});

  @override
  ConsumerState<FcmScope> createState() => _FcmScopeState();
}

class _FcmScopeState extends ConsumerState<FcmScope> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFcm());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!ref.read(authStateProvider).isAuthenticated) return;
    ref.read(notificationsNotifierProvider.notifier).syncUnreadBadge();
  }

  void _onPushMessage() {
    if (!ref.read(authStateProvider).isAuthenticated) return;
    ref.read(notificationsNotifierProvider.notifier).onPushReceived();
  }

  Future<void> _initFcm() async {
    final fcm = ref.read(fcmServiceProvider);
    await fcm.attachListeners(
      onOpenFromNotification: _navigateFromPayload,
      onForegroundMessage: (_) => _onPushMessage(),
    );

    final auth = ref.read(authStateProvider);
    if (auth.isAuthenticated) {
      await syncFcmWithService(fcm);
      await ref.read(notificationsNotifierProvider.notifier).syncUnreadBadge();
    }
  }

  void _navigateFromPayload(NotificationPayload payload) {
    final role = ref.read(authStateProvider).user?.role;
    final path = payload.resolveNavigationPath(role: role);
    if (path == null) return;

    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    ctx.go(path);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.isAuthenticated && next.user != null) {
        final wasAuth = previous?.isAuthenticated ?? false;
        if (!wasAuth || previous?.user?.id != next.user?.id) {
          final fcm = ref.read(fcmServiceProvider);
          syncFcmWithService(fcm);
          ref.read(notificationsNotifierProvider.notifier).syncUnreadBadge();
        }
      }
    });

    return widget.child;
  }
}
