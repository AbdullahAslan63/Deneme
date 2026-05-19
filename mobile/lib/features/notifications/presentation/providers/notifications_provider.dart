import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../domain/entities/notification_entity.dart';

final notificationDataSourceProvider =
    Provider<NotificationDataSource>((ref) {
  return NotificationRemoteDataSource(
    dioClient: ref.watch(dioClientProvider),
  );
});

class NotificationsState {
  final bool isLoading;
  final List<NotificationEntity> items;
  final int unreadCount;
  final String? nextCursor;
  final String? error;

  const NotificationsState({
    this.isLoading = false,
    this.items = const [],
    this.unreadCount = 0,
    this.nextCursor,
    this.error,
  });

  NotificationsState copyWith({
    bool? isLoading,
    List<NotificationEntity>? items,
    int? unreadCount,
    String? nextCursor,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      nextCursor: nextCursor ?? this.nextCursor,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationDataSource _remote;

  NotificationsNotifier(this._remote) : super(const NotificationsState());

  Future<void> load({bool refresh = true}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _remote.list(
        cursor: refresh ? null : state.nextCursor,
      );
      final merged = refresh
          ? result.items
          : [...state.items, ...result.items];
      state = state.copyWith(
        isLoading: false,
        items: merged,
        unreadCount: result.unreadCount,
        nextCursor: result.nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markRead(String id) async {
    await _remote.markRead(id);
    final items = [
      for (final n in state.items)
        if (n.id == id)
          NotificationEntity(
            id: n.id,
            title: n.title,
            body: n.body,
            type: n.type,
            isRead: true,
            data: n.data,
            createdAt: n.createdAt,
          )
        else
          n,
    ];
    state = state.copyWith(
      items: items,
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );
  }

  Future<void> markAllRead() async {
    await _remote.markAllRead();
    final items = [
      for (final n in state.items)
        NotificationEntity(
          id: n.id,
          title: n.title,
          body: n.body,
          type: n.type,
          isRead: true,
          data: n.data,
          createdAt: n.createdAt,
        ),
    ];
    state = state.copyWith(items: items, unreadCount: 0);
  }

  Future<AnnouncementResultEntity?> sendAnnouncement(
    String buildingId, {
    required String title,
    required String body,
  }) async {
    try {
      return await _remote.sendAnnouncement(
        buildingId,
        title: title,
        body: body,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref.watch(notificationDataSourceProvider));
});
