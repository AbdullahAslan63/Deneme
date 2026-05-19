import '../../domain/entities/ticket_update_entity.dart';
import 'ticket_model.dart';

class TicketUpdateModel {
  final String id;
  final String ticketId;
  final String message;
  final String fromRole;
  final DateTime createdAt;

  const TicketUpdateModel({
    required this.id,
    required this.ticketId,
    required this.message,
    required this.fromRole,
    required this.createdAt,
  });

  factory TicketUpdateModel.fromJson(Map<String, dynamic> json) {
    return TicketUpdateModel(
      id: (json['id'] ?? '') as String,
      ticketId: (json['ticketId'] ?? '') as String,
      message: (json['message'] ?? '') as String,
      fromRole: (json['fromRole'] ?? 'MANAGER') as String,
      createdAt: TicketModel.parseDate(json['createdAt']),
    );
  }

  TicketUpdateEntity toEntity() => TicketUpdateEntity(
        id: id,
        ticketId: ticketId,
        message: message,
        fromRole: fromRole,
        createdAt: createdAt,
      );
}
