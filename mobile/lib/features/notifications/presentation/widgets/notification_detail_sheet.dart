import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/notification_entity.dart';
import '../utils/notification_labels.dart';
import '../utils/notification_style.dart';

/// Bildirim detayı — modern alt sayfa; ilgili kayda geçiş.
class NotificationDetailSheet {
  NotificationDetailSheet._();

  static Future<void> show(
    BuildContext context, {
    required NotificationEntity notification,
    required VoidCallback onMarkRead,
    VoidCallback? onNavigate,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationDetailSheetBody(
        notification: notification,
        onMarkRead: onMarkRead,
        onNavigate: onNavigate,
      ),
    );
  }
}

class _NotificationDetailSheetBody extends ConsumerWidget {
  final NotificationEntity notification;
  final VoidCallback onMarkRead;
  final VoidCallback? onNavigate;

  const _NotificationDetailSheetBody({
    required this.notification,
    required this.onMarkRead,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = notification;
    final visual = notificationVisual(n.type);
    final locale = Localizations.localeOf(context).toString();
    final dateStr =
        DateFormat('d MMMM yyyy, HH:mm', locale).format(n.createdAt);
    final t = context.t.features.notifications;
    final role = ref.read(authStateProvider).user?.role;
    final path = n.toPayload().resolveNavigationPath(role: role);
    final canNavigate = path != null && onNavigate != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A0F172A),
                blurRadius: 24,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSizes.spacingM,
              AppSizes.spacingS,
              AppSizes.spacingM,
              AppSizes.spacingXL,
            ),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingM),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(visual.icon, color: visual.color, size: 28),
                  ),
                  const SizedBox(width: AppSizes.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.type.label(context),
                          style: AppTypography.caption.copyWith(
                            color: visual.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!n.isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t.unreadBadge,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingL),
              Text(
                n.title,
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSizes.spacingM),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  n.body,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingXL),
              if (canNavigate)
                SizedBox(
                  height: AppSizes.buttonHeightPrimary,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (!n.isRead) onMarkRead();
                      Navigator.of(context).pop();
                      onNavigate!();
                    },
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(t.viewRelated),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSizes.spacingS),
              SizedBox(
                height: AppSizes.buttonHeightSecondary,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    if (!n.isRead) onMarkRead();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(context.t.common.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
