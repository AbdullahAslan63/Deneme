import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../domain/entities/ticket_entity.dart';
import '../providers/tickets_provider.dart';
import '../utils/ticket_labels.dart';

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
                        child: _TicketCard(
                          ticket: ticket,
                          onTap: () => context.push('/tickets/${ticket.id}'),
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

class _TicketCard extends StatelessWidget {
  final TicketEntity ticket;
  final VoidCallback? onTap;

  const _TicketCard({required this.ticket, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(ticket.status);
    final date = '${ticket.createdAt.day}.${ticket.createdAt.month}.${ticket.createdAt.year}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      child: Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  ticket.title,
                  style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ticket.status.label(context),
                  style: AppTypography.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            ticket.category.label(context),
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            ticket.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            date,
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
    );
  }

  Color _statusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return AppColors.warning;
      case TicketStatus.inProgress:
        return AppColors.primary;
      case TicketStatus.resolved:
        return AppColors.success;
      case TicketStatus.closed:
        return AppColors.textSecondary;
    }
  }
}
