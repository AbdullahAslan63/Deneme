/// Dev preview: gider ve bildirim API'si olmadan Faz 2 ekranlarını gezmek için.
library;

import '../features/expenses/data/datasources/expense_remote_datasource.dart';
import '../features/expenses/data/models/expense_model.dart';
import '../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../features/notifications/data/models/notification_model.dart';
import '../features/notifications/domain/entities/notification_entity.dart';

const _delay = Duration(milliseconds: 200);

class MockExpenseDataSource implements ExpenseDataSource {
  final Map<String, List<ExpenseModel>> _byBuilding = {};

  @override
  Future<List<ExpenseModel>> getBuildingExpenses(
    String buildingId, {
    int? month,
    int? year,
    String? category,
  }) async {
    await Future.delayed(_delay);
    return List<ExpenseModel>.from(_byBuilding[buildingId] ?? []);
  }

  @override
  Future<Map<String, dynamic>> getSummary(
    String buildingId, {
    required int month,
    required int year,
  }) async {
    await Future.delayed(_delay);
    final list = _byBuilding[buildingId] ?? [];
    var total = 0.0;
    for (final e in list) {
      total += e.amount;
    }
    return {
      'month': month,
      'year': year,
      'totalAmount': total.toStringAsFixed(2),
      'currency': 'TRY',
      'byCategory': [],
    };
  }

  @override
  Future<ExpenseModel> createExpense(
    String buildingId, {
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
    String? receiptUrl,
  }) async {
    await Future.delayed(_delay);
    final model = ExpenseModel(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      buildingId: buildingId,
      title: title,
      amount: amount,
      category: category,
      date: date,
      note: note,
      receiptUrl: receiptUrl,
      createdAt: DateTime.now(),
    );
    _byBuilding.putIfAbsent(buildingId, () => []).insert(0, model);
    return model;
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    await Future.delayed(_delay);
    for (final list in _byBuilding.values) {
      list.removeWhere((e) => e.id == expenseId);
    }
  }
}

class MockNotificationDataSource implements NotificationDataSource {
  final List<NotificationEntity> _items = [];

  MockNotificationDataSource() {
    _items.add(
      NotificationEntity(
        id: 'n1',
        title: 'Hoş geldiniz',
        body: 'Dev preview — bildirim kutusu',
        type: NotificationType.system,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<NotificationListResult> list({
    bool unreadOnly = false,
    int limit = 20,
    String? cursor,
  }) async {
    await Future.delayed(_delay);
    var items = List<NotificationEntity>.from(_items);
    if (unreadOnly) {
      items = items.where((n) => !n.isRead).toList();
    }
    return NotificationListResult(
      items: items,
      unreadCount: items.where((n) => !n.isRead).length,
    );
  }

  @override
  Future<NotificationEntity> markRead(String id) async {
    await Future.delayed(_delay);
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      final n = _items[idx];
      _items[idx] = NotificationEntity(
        id: n.id,
        title: n.title,
        body: n.body,
        type: n.type,
        isRead: true,
        data: n.data,
        createdAt: n.createdAt,
      );
      return _items[idx];
    }
    return _items.first;
  }

  @override
  Future<int> markAllRead() async {
    await Future.delayed(_delay);
    for (var i = 0; i < _items.length; i++) {
      final n = _items[i];
      _items[i] = NotificationEntity(
        id: n.id,
        title: n.title,
        body: n.body,
        type: n.type,
        isRead: true,
        data: n.data,
        createdAt: n.createdAt,
      );
    }
    return _items.length;
  }

  @override
  Future<AnnouncementResultEntity> sendAnnouncement(
    String buildingId, {
    required String title,
    required String body,
  }) async {
    await Future.delayed(_delay);
    return const AnnouncementResultEntity(
      created: 3,
      pushSent: 0,
      pushFailed: 0,
    );
  }
}
