import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../l10n/strings.g.dart';
import '../../../buildings/data/buildings_store.dart';
import '../providers/tickets_provider.dart';
import '../utils/ticket_labels.dart';

class ManagerTicketsScreen extends ConsumerStatefulWidget {
  const ManagerTicketsScreen({super.key});

  @override
  ConsumerState<ManagerTicketsScreen> createState() =>
      _ManagerTicketsScreenState();
}

class _ManagerTicketsScreenState extends ConsumerState<ManagerTicketsScreen> {
  String? _buildingId;

  @override
  Widget build(BuildContext context) {
    final buildings = ref.watch(buildingsStoreProvider).value ?? [];
    final state = ref.watch(ticketsNotifierProvider);

    if (_buildingId == null && buildings.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _buildingId = buildings.first.id);
        ref
            .read(ticketsNotifierProvider.notifier)
            .loadBuildingTickets(buildings.first.id);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.features.tickets.managerTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (buildings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSizes.spacingM),
              child: DropdownButtonFormField<String>(
                value: _buildingId,
                decoration: InputDecoration(
                  labelText: context.t.common.buildingName,
                  border: const OutlineInputBorder(),
                ),
                items: buildings
                    .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  setState(() => _buildingId = id);
                  ref.read(ticketsNotifierProvider.notifier).loadBuildingTickets(id);
                },
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final id = _buildingId;
                if (id != null) {
                  await ref
                      .read(ticketsNotifierProvider.notifier)
                      .loadBuildingTickets(id);
                }
              },
              child: state.isLoading && state.tickets.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: AppSizes.screenBodyScrollPadding,
                      itemCount: state.tickets.length,
                      itemBuilder: (context, i) {
                        final t = state.tickets[i];
                        return ListTile(
                          title: Text(t.title),
                          subtitle: Text(
                            '${t.apartmentNumber ?? ''} · ${t.status.label(context)}',
                          ),
                          onTap: () => context.push('/tickets/${t.id}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
