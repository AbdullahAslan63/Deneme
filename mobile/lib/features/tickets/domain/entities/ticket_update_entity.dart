import 'package:equatable/equatable.dart';

class TicketUpdateEntity extends Equatable {
  final String id;
  final String ticketId;
  final String message;
  final String fromRole;
  final DateTime createdAt;

  const TicketUpdateEntity({
    required this.id,
    required this.ticketId,
    required this.message,
    required this.fromRole,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, ticketId, message, fromRole, createdAt];
}
