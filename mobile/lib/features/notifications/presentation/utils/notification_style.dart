import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationVisual {
  final IconData icon;
  final Color color;
  final Color background;

  const NotificationVisual({
    required this.icon,
    required this.color,
    required this.background,
  });
}

NotificationVisual notificationVisual(NotificationType type) {
  switch (type) {
    case NotificationType.dueReminder:
      return const NotificationVisual(
        icon: Icons.schedule_rounded,
        color: AppColors.warning,
        background: AppColors.warningBg,
      );
    case NotificationType.duePaid:
      return const NotificationVisual(
        icon: Icons.payments_rounded,
        color: AppColors.success,
        background: AppColors.successBg,
      );
    case NotificationType.ticketCreated:
    case NotificationType.ticketUpdate:
      return const NotificationVisual(
        icon: Icons.support_agent_rounded,
        color: AppColors.primary,
        background: Color(0xFFE8EEF8),
      );
    case NotificationType.announcement:
      return const NotificationVisual(
        icon: Icons.campaign_rounded,
        color: AppColors.accent,
        background: AppColors.warningBg,
      );
    case NotificationType.system:
      return const NotificationVisual(
        icon: Icons.info_rounded,
        color: AppColors.info,
        background: Color(0xFFDBEAFE),
      );
    case NotificationType.other:
      return const NotificationVisual(
        icon: Icons.notifications_rounded,
        color: AppColors.textSecondary,
        background: AppColors.background,
      );
  }
}
