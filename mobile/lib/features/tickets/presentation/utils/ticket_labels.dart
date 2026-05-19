import 'package:flutter/widgets.dart';

import '../../../../l10n/strings.g.dart';
import '../../domain/entities/ticket_entity.dart';

extension TicketCategoryLabels on TicketCategory {
  String label(BuildContext context) {
    final t = context.t.features.tickets;
    switch (this) {
      case TicketCategory.complaint:
        return t.categoryComplaint;
      case TicketCategory.request:
        return t.categoryRequest;
      case TicketCategory.malfunction:
        return t.categoryMalfunction;
      case TicketCategory.other:
        return t.categoryOther;
    }
  }
}

extension TicketStatusLabels on TicketStatus {
  String label(BuildContext context) {
    final t = context.t.features.tickets;
    switch (this) {
      case TicketStatus.open:
        return t.statusOpen;
      case TicketStatus.inProgress:
        return t.statusInProgress;
      case TicketStatus.resolved:
        return t.statusResolved;
      case TicketStatus.closed:
        return t.statusClosed;
    }
  }
}
