import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/expense_remote_datasource.dart';
import '../../data/models/expense_model.dart';
import '../../domain/entities/expense_entity.dart';

final expenseDataSourceProvider = Provider<ExpenseDataSource>((ref) {
  return ExpenseRemoteDataSource(dioClient: ref.watch(dioClientProvider));
});

class ExpensesState {
  final bool isLoading;
  final List<ExpenseEntity> expenses;
  final ExpenseSummaryEntity? summary;
  final String? error;

  const ExpensesState({
    this.isLoading = false,
    this.expenses = const [],
    this.summary,
    this.error,
  });

  ExpensesState copyWith({
    bool? isLoading,
    List<ExpenseEntity>? expenses,
    ExpenseSummaryEntity? summary,
    String? error,
    bool clearError = false,
  }) {
    return ExpensesState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
      summary: summary ?? this.summary,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ExpensesNotifier extends StateNotifier<ExpensesState> {
  final ExpenseDataSource _remote;

  ExpensesNotifier(this._remote) : super(const ExpensesState());

  Future<void> load(
    String buildingId, {
    int? month,
    int? year,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final models = await _remote.getBuildingExpenses(
        buildingId,
        month: month,
        year: year,
      );
      final expenses = models.map((m) => m.toEntity()).toList();
      ExpenseSummaryEntity? summary;
      if (month != null && year != null) {
        final raw = await _remote.getSummary(
          buildingId,
          month: month,
          year: year,
        );
        summary = _parseSummary(raw);
      }
      state = state.copyWith(
        isLoading: false,
        expenses: expenses,
        summary: summary,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create({
    required String buildingId,
    required String title,
    required double amount,
    required ExpenseCategory category,
    required DateTime date,
    String? note,
    String? receiptUrl,
  }) async {
    try {
      await _remote.createExpense(
        buildingId,
        title: title,
        amount: amount,
        category: ExpenseModel.categoryToApi(category),
        date: date,
        note: note,
        receiptUrl: receiptUrl,
      );
      await load(buildingId, month: date.month, year: date.year);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  ExpenseSummaryEntity _parseSummary(Map<String, dynamic> raw) {
    final total = double.tryParse('${raw['totalAmount']}') ?? 0;
    final byCat = <ExpenseCategorySummary>[];
    final list = raw['byCategory'];
    if (list is List) {
      for (final item in list) {
        if (item is! Map) continue;
        byCat.add(ExpenseCategorySummary(
          category: ExpenseModel.fromJson({
            'id': '',
            'buildingId': '',
            'title': '',
            'amount': '0',
            'category': item['category'],
            'date': DateTime.now().toIso8601String(),
            'createdAt': DateTime.now().toIso8601String(),
          }).toEntity().category,
          amount: double.tryParse('${item['amount']}') ?? 0,
          count: (item['count'] as num?)?.toInt() ?? 0,
        ));
      }
    }
    return ExpenseSummaryEntity(
      month: (raw['month'] as num?)?.toInt() ?? DateTime.now().month,
      year: (raw['year'] as num?)?.toInt() ?? DateTime.now().year,
      totalAmount: total,
      currency: (raw['currency'] as String?) ?? 'TRY',
      byCategory: byCat,
    );
  }
}

final expensesNotifierProvider =
    StateNotifierProvider<ExpensesNotifier, ExpensesState>((ref) {
  return ExpensesNotifier(ref.watch(expenseDataSourceProvider));
});
