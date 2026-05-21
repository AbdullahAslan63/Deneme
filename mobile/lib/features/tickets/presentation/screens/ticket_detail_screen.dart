import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/ticket_entity.dart';
import '../providers/tickets_provider.dart';
import '../utils/ticket_labels.dart';
import '../utils/ticket_status_rules.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    ref.invalidate(ticketDetailProvider(widget.ticketId));
    await ref.read(ticketDetailProvider(widget.ticketId).future);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(ticketDetailProvider(widget.ticketId));
    final isManager =
        ref.watch(authStateProvider).user?.role == UserRole.manager;
    final t = context.t.features.tickets;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.detailTitle),
        centerTitle: true,
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: AppSizes.screenBodyScrollPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e is ApiException ? e.message : t.loadError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spacingM),
                FilledButton(
                  onPressed: _reload,
                  child: Text(context.t.common.tryAgain),
                ),
              ],
            ),
          ),
        ),
        data: (ticket) => RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSizes.screenBodyScrollPadding,
            children: [
              Text(
                ticket.title,
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSizes.spacingS),
              Text(
                [
                  if (ticket.apartmentNumber != null &&
                      ticket.apartmentNumber!.isNotEmpty)
                    ticket.apartmentNumber!,
                  ticket.category.label(context),
                ].join(' · '),
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSizes.spacingM),
              Text(
                ticket.description,
                style: AppTypography.body1
                    .copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSizes.spacingM),
              _StatusBadge(
                label: '${t.statusLabel}: ${ticket.status.label(context)}',
                status: ticket.status,
              ),
              if (ticket.updates.isNotEmpty) ...[
                const SizedBox(height: AppSizes.spacingL),
                Text(t.updatesTitle, style: AppTypography.h4),
                const SizedBox(height: AppSizes.spacingS),
                ...ticket.updates.map(
                  (u) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.spacingS),
                    child: Text(
                      '• ${u.message}',
                      style: AppTypography.body2
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
              if (isManager) ...[
                const SizedBox(height: AppSizes.spacingL),
                _ManagerActions(
                  ticket: ticket,
                  noteController: _noteController,
                  submitting: _submitting,
                  onPatchStatus: _patchStatus,
                  onAddNote: _addNote,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _patchStatus(String ticketId, TicketStatus status) async {
    setState(() => _submitting = true);
    try {
      await ref.read(ticketRepositoryProvider).updateTicketStatus(
            ticketId: ticketId,
            status: status,
          );
      ref.invalidate(ticketDetailProvider(ticketId));
      if (mounted) {
        ref.read(toastProvider.notifier).show(
              context.t.features.tickets.statusUpdated,
              type: ToastType.success,
            );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ref.read(toastProvider.notifier).show(e.message, type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        ref.read(toastProvider.notifier).show(
              e.toString(),
              type: ToastType.error,
            );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _addNote(String ticketId) async {
    final msg = _noteController.text.trim();
    if (msg.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(ticketRepositoryProvider).addManagerUpdate(
            ticketId: ticketId,
            message: msg,
          );
      _noteController.clear();
      ref.invalidate(ticketDetailProvider(ticketId));
      if (mounted) {
        ref.read(toastProvider.notifier).show(
              context.t.features.tickets.noteAdded,
              type: ToastType.success,
            );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ref.read(toastProvider.notifier).show(e.message, type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        ref.read(toastProvider.notifier).show(
              e.toString(),
              type: ToastType.error,
            );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final TicketStatus status;

  const _StatusBadge({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case TicketStatus.open:
        color = AppColors.warning;
      case TicketStatus.inProgress:
        color = AppColors.primary;
      case TicketStatus.resolved:
        color = AppColors.success;
      case TicketStatus.closed:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.body2.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ManagerActions extends StatelessWidget {
  final TicketEntity ticket;
  final TextEditingController noteController;
  final bool submitting;
  final Future<void> Function(String ticketId, TicketStatus status) onPatchStatus;
  final Future<void> Function(String ticketId) onAddNote;

  const _ManagerActions({
    required this.ticket,
    required this.noteController,
    required this.submitting,
    required this.onPatchStatus,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t.features.tickets;
    final nextStatuses = allowedNextStatuses(ticket.status);
    final noteEnabled = canAddManagerNote(ticket.status) && !submitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canChangeStatus(ticket.status) && nextStatuses.isNotEmpty) ...[
          Text(t.changeStatus, style: AppTypography.h4),
          const SizedBox(height: AppSizes.spacingS),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: nextStatuses.map((s) {
              return FilledButton.tonal(
                onPressed: submitting ? null : () => onPatchStatus(ticket.id, s),
                child: Text(s.label(context)),
              );
            }).toList(),
          ),
        ],
        if (ticket.status == TicketStatus.closed) ...[
          Text(
            t.statusClosedHint,
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: AppSizes.spacingL),
        Text(t.managerNote, style: AppTypography.h4),
        const SizedBox(height: AppSizes.spacingS),
        TextField(
          controller: noteController,
          maxLines: 3,
          enabled: noteEnabled,
          decoration: InputDecoration(
            labelText: t.managerNote,
            hintText: noteEnabled ? null : t.noteDisabledClosed,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSizes.spacingM),
        FilledButton(
          onPressed: noteEnabled ? () => onAddNote(ticket.id) : null,
          child: submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.addNote),
        ),
      ],
    );
  }
}
