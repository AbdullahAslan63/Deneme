import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_typography.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../l10n/strings.g.dart';

/// AppBar sağ üst — çan ikonu + okunmamış sayı (sağ üst köşe rozeti).
class NotificationIconButton extends ConsumerWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsNotifierProvider).unreadCount;
    final showBadge = unread > 0;
    final badgeLabel = unread > 99 ? '99+' : unread.toString();

    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.spacingS),
      child: Badge(
        isLabelVisible: showBadge,
        label: Text(
          badgeLabel,
          style: AppTypography.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            height: 1,
          ),
        ),
        backgroundColor: AppColors.error,
        offset: const Offset(4, -4),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: IconButton(
          tooltip: context.t.common.notifications,
          onPressed: () => context.push('/notifications'),
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

/// Dashboard açılışında okunmamış sayıyı günceller.
void prefetchNotifications(WidgetRef ref) {
  ref.read(notificationsNotifierProvider.notifier).syncUnreadBadge();
}
