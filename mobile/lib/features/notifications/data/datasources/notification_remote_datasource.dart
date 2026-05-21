import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';

abstract class NotificationDataSource {
  Future<NotificationListResult> list({
    bool unreadOnly = false,
    int limit = 20,
    String? cursor,
  });

  Future<NotificationEntity> markRead(String id);
  Future<int> markAllRead();
  Future<AnnouncementResultEntity> sendAnnouncement(
    String buildingId, {
    required String title,
    required String body,
  });
}

class NotificationRemoteDataSource implements NotificationDataSource {
  final DioClient _dioClient;

  NotificationRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  @override
  Future<NotificationListResult> list({
    bool unreadOnly = false,
    int limit = 20,
    String? cursor,
  }) async {
    final query = <String, dynamic>{
      'unreadOnly': unreadOnly,
      'limit': limit,
    };
    if (cursor != null) query['cursor'] = cursor;

    final response = await _dioClient.get(
      ApiConstants.notifications,
      queryParameters: query,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((j) =>
            NotificationModel.fromJson(j as Map<String, dynamic>).toEntity())
        .toList();
    return NotificationListResult(
      items: items,
      nextCursor: data['nextCursor'] as String?,
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<NotificationEntity> markRead(String id) async {
    final response = await _dioClient.patch(
      ApiConstants.notificationRead(id),
    );
    return NotificationModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    ).toEntity();
  }

  @override
  Future<int> markAllRead() async {
    final response = await _dioClient.patch(
      ApiConstants.notificationsReadAll,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return (data['updated'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<AnnouncementResultEntity> sendAnnouncement(
    String buildingId, {
    required String title,
    required String body,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.buildingAnnouncements(buildingId),
      data: {'title': title, 'body': body},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return AnnouncementResultEntity(
      created: (data['created'] as num?)?.toInt() ?? 0,
      pushSent: (data['pushSent'] as num?)?.toInt() ?? 0,
      pushFailed: (data['pushFailed'] as num?)?.toInt() ?? 0,
      pushSkipped: (data['pushSkipped'] as num?)?.toInt() ?? 0,
    );
  }
}
