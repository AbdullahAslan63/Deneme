import 'package:equatable/equatable.dart';

import 'ticket_update_entity.dart';

enum TicketCategory { complaint, request, malfunction, other }

enum TicketStatus { open, inProgress, resolved, closed }

class TicketEntity extends Equatable {
  final String id;
  final String apartmentId;
  final String userId;
  final String title;
  final String description;
  final TicketCategory category;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? apartmentNumber;
  final List<TicketUpdateEntity> updates;

  const TicketEntity({
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

  @override
  List<Object?> get props => [
        id,
        apartmentId,
        userId,
        title,
        description,
        category,
        status,
        createdAt,
        updatedAt,
        apartmentNumber,
        updates,
      ];
}
