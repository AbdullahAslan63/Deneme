import 'package:flutter/widgets.dart';

import '../../../../core/notifications/notification_payload.dart';
import '../../../../l10n/strings.g.dart';
import '../../domain/entities/notification_entity.dart';

extension NotificationTypeLabels on NotificationType {
  String label(BuildContext context) {
    final t = context.t.features.notifications;
    switch (this) {
      case NotificationType.dueReminder:
        return t.typeDueReminder;
      case NotificationType.duePaid:
        return t.typeDuePaid;
      case NotificationType.ticketCreated:
        return t.typeTicketCreated;
      case NotificationType.ticketUpdate:
        return t.typeTicketUpdate;
      case NotificationType.announcement:
        return t.typeAnnouncement;
      case NotificationType.system:
        return t.typeSystem;
      case NotificationType.other:
        return t.typeOther;
    }
  }

  /// Backend `Notification.type` string değeri.
  String toApiType() {
    switch (this) {
      case NotificationType.dueReminder:
        return 'DUE_REMINDER';
      case NotificationType.duePaid:
        return 'DUE_PAID';
      case NotificationType.ticketCreated:
        return 'TICKET_CREATED';
      case NotificationType.ticketUpdate:
        return 'TICKET_UPDATE';
      case NotificationType.announcement:
        return 'ANNOUNCEMENT';
      case NotificationType.system:
        return 'SYSTEM';
      case NotificationType.other:
        return 'OTHER';
    }
  }
}

extension NotificationEntityNavigation on NotificationEntity {
  NotificationPayload toPayload() {
    String? str(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return NotificationPayload(
      type: type.toApiType(),
      notificationId: id,
      ticketId: str(data?['ticketId']),
      buildingId: str(data?['buildingId']),
      status: str(data?['status']),
      route: str(data?['route']),
    );
  }
}
