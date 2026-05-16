import 'package:equatable/equatable.dart';

enum DueStatus { pending, paid, overdue, waived }

class DueEntity extends Equatable {
  final String id;
  final String apartmentId;
  final String apartmentNumber;
  final double amount;
  final String currency;
  final int month;
  final int year;
  final DateTime? dueDate;
  final DueStatus status;
  final DateTime? paidAt;
  final int overdueDays;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DueEntity({
    required this.id,
    required this.apartmentId,
    required this.apartmentNumber,
    required this.amount,
    required this.currency,
    required this.month,
    required this.year,
    this.dueDate,
    required this.status,
    this.paidAt,
    this.overdueDays = 0,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        apartmentId,
        apartmentNumber,
        amount,
        currency,
        month,
        year,
        dueDate,
        status,
        paidAt,
        overdueDays,
        note,
        createdAt,
        updatedAt,
      ];
}
