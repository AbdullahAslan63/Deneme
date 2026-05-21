import '../../features/auth/domain/entities/user_entity.dart';

/// FCM `data` alanı — backend tüm değerleri string gönderir.
class NotificationPayload {
  final String? type;
  final String? notificationId;
  final String? ticketId;
  final String? buildingId;
  final String? status;
  final String? route;

  const NotificationPayload({
    this.type,
    this.notificationId,
    this.ticketId,
    this.buildingId,
    this.status,
    this.route,
  });

  factory NotificationPayload.fromFcmData(Map<String, dynamic> data) {
    String? str(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return NotificationPayload(
      type: str(data['type']),
      notificationId: str(data['notificationId']),
      ticketId: str(data['ticketId']),
      buildingId: str(data['buildingId']),
      status: str(data['status']),
      route: str(data['route']),
    );
  }

  /// GoRouter yolu; rol ve `type` ile backend deep link matrisine uyumlu.
  String? resolveNavigationPath({UserRole? role}) {
    final normalized = type?.toUpperCase();
    final tid = ticketId;

    switch (normalized) {
      case 'TICKET_CREATED':
        if (tid != null) {
          return role == UserRole.manager ? '/tickets/$tid' : null;
        }
        return role == UserRole.manager ? '/manager/tickets' : null;
      case 'TICKET_UPDATE':
        if (tid != null) return '/tickets/$tid';
        return route ?? '/resident-dashboard';
      case 'ANNOUNCEMENT':
        return route ?? '/notifications';
      case 'DUE_PAID':
      case 'DUE_REMINDER':
        return route ?? '/resident-dashboard';
      default:
        if (route != null && route!.isNotEmpty) return route;
        return '/notifications';
    }
  }
}
