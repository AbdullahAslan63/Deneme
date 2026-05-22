import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/notification_entity.dart';
import '../utils/notification_labels.dart';
import '../utils/notification_style.dart';

class NotificationListTile extends StatelessWidget {
  final NotificationEntity notification;
  final String locale;
  final VoidCallback onTap;

  const NotificationListTile({
    super.key,
    required this.notification,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final visual = notificationVisual(n.type);
    final dateStr = DateFormat('d MMM, HH:mm', locale).format(n.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingS),
      child: Material(
        color: n.isRead
            ? AppColors.surface
            : AppColors.primary.withValues(alpha: 0.04),
        elevation: n.isRead ? 0 : 1,
        shadowColor: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(
                color: n.isRead
                    ? AppColors.border
                    : AppColors.primary.withValues(alpha: 0.22),
              ),
            ),
            padding: const EdgeInsets.all(AppSizes.spacingM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: visual.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(visual.icon, color: visual.color, size: 24),
                ),
                const SizedBox(width: AppSizes.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: AppTypography.body1.copyWith(
                                fontWeight:
                                    n.isRead ? FontWeight.w600 : FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: visual.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          n.type.label(context),
                          style: AppTypography.caption.copyWith(
                            color: visual.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingXS),
                      Text(
                        n.body,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSizes.spacingXS),
                      Text(
                        dateStr,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.spacingS),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textDisabled,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
