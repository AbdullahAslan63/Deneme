import '../../domain/entities/ticket_entity.dart';

/// Backend `ticketService` — yalnızca ileri geçişler (`ALLOWED_STATUS_TRANSITIONS`).
List<TicketStatus> allowedNextStatuses(TicketStatus current) {
  switch (current) {
    case TicketStatus.open:
      return [
        TicketStatus.inProgress,
        TicketStatus.resolved,
        TicketStatus.closed,
      ];
    case TicketStatus.inProgress:
      return [TicketStatus.resolved, TicketStatus.closed];
    case TicketStatus.resolved:
      return [TicketStatus.closed];
    case TicketStatus.closed:
      return [];
  }
}

/// `POST .../updates` — yalnızca OPEN / IN_PROGRESS (aksi 409).
bool canAddManagerNote(TicketStatus status) {
  return status == TicketStatus.open || status == TicketStatus.inProgress;
}

bool canChangeStatus(TicketStatus status) => status != TicketStatus.closed;
