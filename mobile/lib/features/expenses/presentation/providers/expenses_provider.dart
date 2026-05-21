import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
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
  final String? buildingId;
  final int? month;
  final int? year;

  const ExpensesState({
    this.isLoading = false,
    this.expenses = const [],
    this.summary,
    this.error,
    this.buildingId,
    this.month,
    this.year,
  });

  ExpensesState copyWith({
    bool? isLoading,
    List<ExpenseEntity>? expenses,
    ExpenseSummaryEntity? summary,
    String? error,
    String? buildingId,
    int? month,
    int? year,
    bool clearError = false,
    bool clearSummary = false,
  }) {
    return ExpensesState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
      summary: clearSummary ? null : (summary ?? this.summary),
      error: clearError ? null : (error ?? this.error),
      buildingId: buildingId ?? this.buildingId,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}

class ExpensesNotifier extends StateNotifier<ExpensesState> {
  final ExpenseDataSource _remote;

  ExpensesNotifier(this._remote) : super(const ExpensesState());

  String _err(Object e) => e is ApiException ? e.message : e.toString();

  Future<void> load(
    String buildingId, {
    int? month,
    int? year,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      buildingId: buildingId,
      month: month,
      year: year,
    );
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
      state = state.copyWith(isLoading: false, error: _err(e));
    }
  }

  Future<void> reload() async {
    final id = state.buildingId;
    if (id == null) return;
    await load(id, month: state.month, year: state.year);
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
      await load(buildingId, month: state.month, year: state.year);
      return true;
    } catch (e) {
      state = state.copyWith(error: _err(e));
      return false;
    }
  }

  Future<bool> update({
    required String expenseId,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
    String? receiptUrl,
  }) async {
    try {
      await _remote.updateExpense(
        expenseId,
        title: title,
        amount: amount,
        category:
            category != null ? ExpenseModel.categoryToApi(category) : null,
        date: date,
        note: note,
        receiptUrl: receiptUrl,
      );
      await reload();
      return true;
    } catch (e) {
      state = state.copyWith(error: _err(e));
      return false;
    }
  }

  Future<bool> delete(String expenseId) async {
    try {
      await _remote.deleteExpense(expenseId);
      await reload();
      return true;
    } catch (e) {
      state = state.copyWith(error: _err(e));
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
          category: ExpenseModel.parseCategoryApi('${item['category']}'),
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
