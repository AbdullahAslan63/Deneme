import '../entities/ticket_entity.dart';

abstract class TicketRepository {
  Future<List<TicketEntity>> getMyTickets({
    TicketStatus? status,
    TicketCategory? category,
  });

  Future<List<TicketEntity>> getBuildingTickets(
    String buildingId, {
    TicketStatus? status,
    TicketCategory? category,
  });

  Future<TicketEntity> getTicketById(String ticketId);

  Future<TicketEntity> createTicket({
    required String apartmentId,
    required String title,
    required String description,
    required TicketCategory category,
  });

  Future<TicketEntity> addManagerUpdate({
    required String ticketId,
    required String message,
  });

  Future<TicketEntity> updateTicketStatus({
    required String ticketId,
    required TicketStatus status,
  });
}
