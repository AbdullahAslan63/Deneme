import '../../domain/entities/expense_entity.dart';

class ExpenseModel {
  final String id;
  final String buildingId;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final String? receiptUrl;
  final DateTime createdAt;

  const ExpenseModel({
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

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final amountRaw = json['amount'];
    final amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse('$amountRaw') ?? 0;

    return ExpenseModel(
      id: (json['id'] ?? '') as String,
      buildingId: (json['buildingId'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      amount: amount,
      category: (json['category'] ?? 'OTHER') as String,
      date: _parseDate(json['date']),
      note: json['note'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  ExpenseEntity toEntity() => ExpenseEntity(
        id: id,
        buildingId: buildingId,
        title: title,
        amount: amount,
        category: _parseCategory(category),
        date: date,
        note: note,
        receiptUrl: receiptUrl,
        createdAt: createdAt,
      );

  static ExpenseCategory parseCategoryApi(String value) =>
      _parseCategory(value);

  static ExpenseCategory _parseCategory(String value) {
    switch (value.toUpperCase()) {
      case 'CLEANING':
        return ExpenseCategory.cleaning;
      case 'ELEVATOR':
        return ExpenseCategory.elevator;
      case 'ELECTRICITY':
        return ExpenseCategory.electricity;
      case 'WATER':
        return ExpenseCategory.water;
      case 'INSURANCE':
        return ExpenseCategory.insurance;
      case 'REPAIR':
        return ExpenseCategory.repair;
      case 'GARDEN':
        return ExpenseCategory.garden;
      default:
        return ExpenseCategory.other;
    }
  }

  static String categoryToApi(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.cleaning:
        return 'CLEANING';
      case ExpenseCategory.elevator:
        return 'ELEVATOR';
      case ExpenseCategory.electricity:
        return 'ELECTRICITY';
      case ExpenseCategory.water:
        return 'WATER';
      case ExpenseCategory.insurance:
        return 'INSURANCE';
      case ExpenseCategory.repair:
        return 'REPAIR';
      case ExpenseCategory.garden:
        return 'GARDEN';
      case ExpenseCategory.other:
        return 'OTHER';
    }
  }
}
