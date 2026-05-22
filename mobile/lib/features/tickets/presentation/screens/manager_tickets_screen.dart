import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/notification_icon_button.dart';
import '../providers/manager_open_tickets_count_provider.dart';
import '../../../buildings/data/buildings_store.dart';
import '../providers/tickets_provider.dart';
import '../widgets/ticket_list_card.dart';

class ManagerTicketsScreen extends ConsumerStatefulWidget {
  const ManagerTicketsScreen({super.key});

  @override
  ConsumerState<ManagerTicketsScreen> createState() =>
      _ManagerTicketsScreenState();
}

class _ManagerTicketsScreenState extends ConsumerState<ManagerTicketsScreen> {
  String? _buildingId;

  Future<void> _load(String buildingId) {
    return ref
        .read(ticketsNotifierProvider.notifier)
        .loadBuildingTickets(buildingId);
  }

  Future<void> _openTicket(String ticketId) async {
    await context.push('/tickets/$ticketId');
    final id = _buildingId;
    if (id != null && mounted) {
      await _load(id);
      ref.invalidate(managerOpenTicketsCountProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildings = ref.watch(buildingsStoreProvider).value ?? [];
    final state = ref.watch(ticketsNotifierProvider);
    final t = context.t.features.tickets;

    if (_buildingId == null && buildings.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _buildingId = buildings.first.id);
        _load(buildings.first.id);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.managerTitle),
        centerTitle: true,
        actions: const [NotificationIconButton()],
      ),
      body: Column(
        children: [
          if (buildings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSizes.spacingM),
              child: DropdownButtonFormField<String>(
                initialValue: _buildingId,
                decoration: InputDecoration(
                  labelText: context.t.common.buildingName,
                  border: const OutlineInputBorder(),
                ),
                items: buildings
                    .map(
                      (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  setState(() => _buildingId = id);
                  _load(id);
                },
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final id = _buildingId;
                if (id != null) await _load(id);
              },
              child: _buildList(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, TicketsState state) {
    final t = context.t.features.tickets;
    if (state.isLoading && state.tickets.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (state.error != null && state.tickets.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
          Center(
            child: Padding(
              padding: AppSizes.screenBodyScrollPadding,
              child: Column(
                children: [
                  Text(
                    state.error ?? t.loadError,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  FilledButton(
                    onPressed: () {
                      final id = _buildingId;
                      if (id != null) _load(id);
                    },
                    child: Text(context.t.common.tryAgain),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (state.tickets.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyStateWidget(
            icon: Icons.support_agent_outlined,
            title: context.t.features.tickets.emptyTitle,
            subtitle: context.t.features.tickets.emptySubtitle,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSizes.screenBodyScrollPadding,
      itemCount: state.tickets.length,
      itemBuilder: (context, i) {
        final ticket = state.tickets[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
          child: TicketListCard(
            ticket: ticket,
            onTap: () => _openTicket(ticket.id),
          ),
        );
      },
    );
  }
}
