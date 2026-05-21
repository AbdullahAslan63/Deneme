import 'package:equatable/equatable.dart';

enum ExpenseCategory {
  cleaning,
  elevator,
  electricity,
  water,
  insurance,
  repair,
  garden,
  other,
}

class ExpenseEntity extends Equatable {
  final String id;
  final String buildingId;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;
  final String? receiptUrl;
  final DateTime createdAt;

  const ExpenseEntity({
    required this.id,
    required this.buildingId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.receiptUrl,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, buildingId, title, amount, category, date, note, receiptUrl, createdAt];
}

class ExpenseSummaryEntity extends Equatable {
  final int month;
  final int year;
  final double totalAmount;
  final String currency;
  final List<ExpenseCategorySummary> byCategory;

  const ExpenseSummaryEntity({
    required this.month,
    required this.year,
    required this.totalAmount,
    required this.currency,
    required this.byCategory,
  });

  @override
  List<Object?> get props => [month, year, totalAmount, currency, byCategory];
}

class ExpenseCategorySummary extends Equatable {
  final ExpenseCategory category;
  final double amount;
  final int count;

  const ExpenseCategorySummary({
    required this.category,
    required this.amount,
    required this.count,
  });

  @override
  List<Object?> get props => [category, amount, count];
}
