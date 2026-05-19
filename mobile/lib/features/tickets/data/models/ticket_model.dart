import '../../domain/entities/ticket_entity.dart';
import 'ticket_update_model.dart';

class TicketModel {
  final String id;
  final String apartmentId;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? apartmentNumber;
  final List<TicketUpdateModel> updates;

  const TicketModel({
    required this.id,
    required this.apartmentId,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.apartmentNumber,
    this.updates = const [],
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final updatesJson = json['updates'];
    final updates = updatesJson is List
        ? updatesJson
            .map((e) =>
                TicketUpdateModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <TicketUpdateModel>[];

    String? aptNum;
    final flat = json['apartmentNumber'];
    if (flat is String && flat.isNotEmpty) {
      aptNum = flat;
    } else {
      final apt = json['apartment'];
      if (apt is Map && apt['number'] is String) {
        aptNum = apt['number'] as String;
      }
    }

    return TicketModel(
      id: (json['id'] ?? '') as String,
      apartmentId: (json['apartmentId'] ?? '') as String,
      userId: (json['userId'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      category: (json['category'] ?? 'OTHER') as String,
      status: (json['status'] ?? 'OPEN') as String,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      apartmentNumber: aptNum,
      updates: updates,
    );
  }

  static DateTime parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  TicketEntity toEntity() => TicketEntity(
        id: id,
        apartmentId: apartmentId,
        userId: userId,
        title: title,
        description: description,
        category: _parseCategory(category),
        status: _parseStatus(status),
        createdAt: createdAt,
        updatedAt: updatedAt,
        apartmentNumber: apartmentNumber,
        updates: updates.map((u) => u.toEntity()).toList(),
      );

  static TicketCategory _parseCategory(String value) {
    switch (value.toUpperCase()) {
      case 'COMPLAINT':
        return TicketCategory.complaint;
      case 'REQUEST':
        return TicketCategory.request;
      case 'MALFUNCTION':
        return TicketCategory.malfunction;
      default:
        return TicketCategory.other;
    }
  }

  static TicketStatus _parseStatus(String value) {
    switch (value.toUpperCase()) {
      case 'IN_PROGRESS':
        return TicketStatus.inProgress;
      case 'RESOLVED':
        return TicketStatus.resolved;
      case 'CLOSED':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }

  static String categoryToApi(TicketCategory category) {
    switch (category) {
      case TicketCategory.complaint:
        return 'COMPLAINT';
      case TicketCategory.request:
        return 'REQUEST';
      case TicketCategory.malfunction:
        return 'MALFUNCTION';
      case TicketCategory.other:
        return 'OTHER';
    }
  }

  static String statusToApi(TicketStatus status) {
    switch (status) {
      case TicketStatus.inProgress:
        return 'IN_PROGRESS';
      case TicketStatus.resolved:
        return 'RESOLVED';
      case TicketStatus.closed:
        return 'CLOSED';
      case TicketStatus.open:
        return 'OPEN';
    }
  }
}
