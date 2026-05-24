import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
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
  final bool isLoadingMore;
  final List<NotificationEntity> items;
  final int unreadCount;
  final String? nextCursor;
  final String? error;

  const NotificationsState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.items = const [],
    this.unreadCount = 0,
    this.nextCursor,
    this.error,
  });

  bool get canLoadMore =>
      nextCursor != null && nextCursor!.isNotEmpty && !isLoading && !isLoadingMore;

  NotificationsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<NotificationEntity>? items,
    int? unreadCount,
    String? nextCursor,
    String? error,
    bool clearError = false,
    bool clearNextCursor = false,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationDataSource _remote;
  Timer? _badgeSyncDebounce;

  NotificationsNotifier(this._remote) : super(const NotificationsState());

  @override
  void dispose() {
    _badgeSyncDebounce?.cancel();
    super.dispose();
  }

  String _err(Object e) => e is ApiException ? e.message : e.toString();

  /// Rozeti API ile senkronize eder (liste ekranını etkilemez).
  Future<void> syncUnreadBadge() async {
    try {
      final result = await _remote.list(limit: 1);
      state = state.copyWith(unreadCount: result.unreadCount);
    } catch (_) {
      // Ağ hatasında mevcut (optimistic) sayı korunur.
    }
  }

  /// FCM push geldiğinde: önce anında +1, ardından sunucudan doğrula.
  void onPushReceived() {
    state = state.copyWith(unreadCount: state.unreadCount + 1);

    _badgeSyncDebounce?.cancel();
    _badgeSyncDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(syncUnreadBadge());
    });

    if (state.items.isNotEmpty) {
      unawaited(load(refresh: true));
    }
  }

  Future<void> load({bool refresh = true}) async {
    if (!refresh && !state.canLoadMore) return;

    state = state.copyWith(
      isLoading: refresh,
      isLoadingMore: !refresh,
      clearError: true,
    );
    try {
      final result = await _remote.list(
        cursor: refresh ? null : state.nextCursor,
      );
      final merged = refresh
          ? result.items
          : [...state.items, ...result.items];
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        items: merged,
        unreadCount: result.unreadCount,
        nextCursor: result.nextCursor,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: _err(e),
      );
    }
  }

  Future<void> loadMore() => load(refresh: false);

  Future<void> markRead(String id) async {
    await _remote.markRead(id);
    final items = [
      for (final n in state.items)
        if (n.id == id)
          NotificationEntity(
            id: n.id,
            userId: n.userId,
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
          userId: n.userId,
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
      state = state.copyWith(error: _err(e));
      return null;
    }
  }
}

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref.watch(notificationDataSourceProvider));
});
