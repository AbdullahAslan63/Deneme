import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../buildings/data/buildings_store.dart';
import '../../domain/entities/ticket_entity.dart';
import 'tickets_provider.dart';

/// Yönetici ana sayfa — açık + işlemde talep sayısı (tüm binalar).
final managerOpenTicketsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final buildings = ref.watch(buildingsStoreProvider).value;
  if (buildings == null || buildings.isEmpty) return 0;

  final repo = ref.watch(ticketRepositoryProvider);
  var count = 0;

  for (final building in buildings) {
    try {
      final tickets = await repo.getBuildingTickets(building.id);
      count += tickets
          .where(
            (t) =>
                t.status == TicketStatus.open ||
                t.status == TicketStatus.inProgress,
          )
          .length;
    } catch (_) {
      // Tek bina hatası tüm sayacı düşürmez.
    }
  }

  return count;
});
