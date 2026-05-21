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

  /// Backend JSON şekline uygun örnek giderler (`b1`, `b2`).
  void seedPreview() {
    final now = DateTime.now();
    _byBuilding['b1'] = [
      ExpenseModel(
        id: 'exp_seed_1',
        buildingId: 'b1',
        title: 'Asansör bakımı',
        amount: 4500,
        category: 'ELEVATOR',
        date: DateTime(now.year, now.month, 5),
        note: 'Yıllık sözleşme',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ExpenseModel(
        id: 'exp_seed_2',
        buildingId: 'b1',
        title: 'Temizlik',
        amount: 1200,
        category: 'CLEANING',
        date: DateTime(now.year, now.month, 12),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
    _byBuilding['b2'] = [
      ExpenseModel(
        id: 'exp_seed_3',
        buildingId: 'b2',
        title: 'Elektrik faturası',
        amount: 3200.5,
        category: 'ELECTRICITY',
        date: DateTime(now.year, now.month, 8),
        createdAt: now,
      ),
    ];
  }

  @override
  Future<List<ExpenseModel>> getBuildingExpenses(
    String buildingId, {
    int? month,
    int? year,
    String? category,
  }) async {
    await Future.delayed(_delay);
    var list = List<ExpenseModel>.from(_byBuilding[buildingId] ?? []);
    if (month != null) {
      list = list.where((e) => e.date.month == month).toList();
    }
    if (year != null) {
      list = list.where((e) => e.date.year == year).toList();
    }
    if (category != null) {
      list = list.where((e) => e.category == category).toList();
    }
    return list;
  }

  @override
  Future<Map<String, dynamic>> getSummary(
    String buildingId, {
    required int month,
    required int year,
  }) async {
    await Future.delayed(_delay);
    final list = await getBuildingExpenses(
      buildingId,
      month: month,
      year: year,
    );
    final byCat = <String, Map<String, dynamic>>{};
    var total = 0.0;
    for (final e in list) {
      total += e.amount;
      final cat = e.category;
      byCat.putIfAbsent(cat, () => {'category': cat, 'amount': 0.0, 'count': 0});
      byCat[cat]!['amount'] =
          (byCat[cat]!['amount'] as double) + e.amount;
      byCat[cat]!['count'] = (byCat[cat]!['count'] as int) + 1;
    }
    return {
      'month': month,
      'year': year,
      'totalAmount': total.toStringAsFixed(2),
      'currency': 'TRY',
      'byCategory': byCat.values
          .map(
            (m) => {
              'category': m['category'],
              'amount': (m['amount'] as double).toStringAsFixed(2),
              'count': m['count'],
            },
          )
          .toList(),
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
  Future<ExpenseModel> updateExpense(
    String expenseId, {
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    String? receiptUrl,
  }) async {
    await Future.delayed(_delay);
    for (final list in _byBuilding.values) {
      final idx = list.indexWhere((e) => e.id == expenseId);
      if (idx < 0) continue;
      final old = list[idx];
      final updated = ExpenseModel(
        id: old.id,
        buildingId: old.buildingId,
        title: title ?? old.title,
        amount: amount ?? old.amount,
        category: category ?? old.category,
        date: date ?? old.date,
        note: note ?? old.note,
        receiptUrl: receiptUrl ?? old.receiptUrl,
        createdAt: old.createdAt,
      );
      list[idx] = updated;
      return updated;
    }
    throw StateError('Expense not found: $expenseId');
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

  /// `GET /notifications` yanıtıyla uyumlu örnek kayıtlar.
  void seedPreview() {
    _items.clear();
    final now = DateTime.now();
    _items.addAll([
      NotificationEntity(
        id: 'n_seed_ticket_created',
        userId: 'dev_manager_1',
        title: 'Yeni talep',
        body: 'Asansör gürültüsü — Çamlık Apartmanı',
        type: NotificationType.ticketCreated,
        isRead: false,
        data: {
          'type': 'TICKET_CREATED',
          'ticketId': 'ticket_seed_1',
          'buildingId': 'b1',
          'apartmentId': 'a1_1',
          'category': 'COMPLAINT',
          'status': 'OPEN',
          'route': '/manager/tickets',
        },
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationEntity(
        id: 'n_seed_announcement',
        userId: 'dev_manager_1',
        title: 'Su kesintisi',
        body: 'Yarın 10:00–14:00 arası planlı bakım.',
        type: NotificationType.announcement,
        isRead: true,
        data: {
          'type': 'ANNOUNCEMENT',
          'buildingId': 'b1',
          'route': '/notifications',
        },
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationEntity(
        id: 'n_seed_system',
        userId: 'dev_manager_1',
        title: 'Dev preview',
        body: 'Bildirim kutusu — mock veri',
        type: NotificationType.system,
        isRead: false,
        data: {'type': 'SYSTEM', 'route': '/notifications'},
        createdAt: now,
      ),
    ]);
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
        userId: n.userId,
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
        userId: n.userId,
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
    _items.insert(
      0,
      NotificationEntity(
        id: 'n_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'dev_manager_1',
        title: title,
        body: body,
        type: NotificationType.announcement,
        isRead: false,
        data: {
          'type': 'ANNOUNCEMENT',
          'buildingId': buildingId,
          'route': '/notifications',
        },
        createdAt: DateTime.now(),
      ),
    );
    return const AnnouncementResultEntity(
      created: 3,
      pushSent: 0,
      pushFailed: 0,
      pushSkipped: 3,
    );
  }
}
