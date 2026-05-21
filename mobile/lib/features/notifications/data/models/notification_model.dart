import '../../domain/entities/notification_entity.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.data,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? data;
    final raw = json['data'];
    if (raw is Map) {
      data = Map<String, dynamic>.from(raw);
    }

    return NotificationModel(
      id: (json['id'] ?? '') as String,
      userId: (json['userId'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      type: (json['type'] ?? 'SYSTEM') as String,
      isRead: json['isRead'] == true,
      data: data,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  NotificationEntity toEntity() => NotificationEntity(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: _parseType(type),
        isRead: isRead,
        data: data,
        createdAt: createdAt,
      );

  static NotificationType _parseType(String value) {
    switch (value.toUpperCase()) {
      case 'TICKET_CREATED':
        return NotificationType.ticketCreated;
      case 'TICKET_UPDATE':
        return NotificationType.ticketUpdate;
      case 'ANNOUNCEMENT':
        return NotificationType.announcement;
      case 'DUE_REMINDER':
        return NotificationType.dueReminder;
      case 'DUE_PAID':
        return NotificationType.duePaid;
      case 'SYSTEM':
        return NotificationType.system;
      default:
        return NotificationType.other;
    }
  }
}

class NotificationListResult {
  final List<NotificationEntity> items;
  final String? nextCursor;
  final int unreadCount;

  const NotificationListResult({
    required this.items,
    this.nextCursor,
    required this.unreadCount,
  });
}
