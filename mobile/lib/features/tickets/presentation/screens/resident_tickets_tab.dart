import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../providers/tickets_provider.dart';
import '../widgets/ticket_list_card.dart';

class ResidentTicketsTab extends ConsumerStatefulWidget {
  const ResidentTicketsTab({super.key});

  @override
  ConsumerState<ResidentTicketsTab> createState() => _ResidentTicketsTabState();
}

class _ResidentTicketsTabState extends ConsumerState<ResidentTicketsTab> {
  bool _requested = false;

  @override
  Widget build(BuildContext context) {
    final ticketsState = ref.watch(ticketsNotifierProvider);
    final t = context.t.features.tickets;

    if (!_requested) {
      _requested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(ticketsNotifierProvider.notifier).loadMyTickets();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          t.newTicket,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(ticketsNotifierProvider.notifier).loadMyTickets(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: AppSizes.screenBodyScrollPadding.copyWith(
                bottom: AppSizes.spacingXL + 72,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    t.myTickets,
                    style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  if (ticketsState.isLoading && ticketsState.tickets.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: AppSizes.spacingXL),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (ticketsState.tickets.isEmpty)
                    EmptyStateWidget(
                      icon: Icons.support_agent_outlined,
                      title: t.emptyTitle,
                      subtitle: t.emptySubtitle,
                    )
                  else
                    ...ticketsState.tickets.map(
                      (ticket) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
                        child: TicketListCard(
                          ticket: ticket,
                          showSubtitleMeta: false,
                          descriptionMaxLines: 1,
                          onTap: () async {
                            await context.push('/tickets/${ticket.id}');
                            if (mounted) {
                              await ref
                                  .read(ticketsNotifierProvider.notifier)
                                  .loadMyTickets();
                            }
                          },
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    final created = await context.push<bool>('/tickets/new');
    if (created == true && mounted) {
      await ref.read(ticketsNotifierProvider.notifier).loadMyTickets();
    }
  }
}
