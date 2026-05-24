import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/ticket_update_entity.dart';
import '../providers/manager_open_tickets_count_provider.dart';
import '../providers/tickets_provider.dart';
import '../utils/ticket_labels.dart';
import '../utils/ticket_status_rules.dart';
import '../widgets/ticket_status_stepper.dart';

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
      backgroundColor: AppColors.background,
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
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSizes.screenBodyScrollPadding,
            children: [
              _TicketHeaderCard(
                ticket: ticket,
                showSubtitleMeta: isManager,
                showStatusChip: isManager,
              ),
              const SizedBox(height: AppSizes.spacingM),
              _SurfaceSection(
                child: Text(
                  ticket.description,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ),
              if (ticket.updates.isNotEmpty) ...[
                const SizedBox(height: AppSizes.spacingL),
                Text(
                  t.updatesTitle,
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingM),
                _UpdatesTimeline(updates: ticket.updates),
              ],
              if (!isManager) ...[
                const SizedBox(height: AppSizes.spacingL),
                TicketStatusStepper(currentStatus: ticket.status),
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
      ref.invalidate(managerOpenTicketsCountProvider);
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

class _TicketHeaderCard extends StatelessWidget {
  final TicketEntity ticket;
  final bool showSubtitleMeta;
  final bool showStatusChip;

  const _TicketHeaderCard({
    required this.ticket,
    this.showSubtitleMeta = true,
    this.showStatusChip = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(ticket.status);
    final meta = showSubtitleMeta
        ? [
            if (ticket.apartmentNumber != null &&
                ticket.apartmentNumber!.isNotEmpty)
              ticket.apartmentNumber!,
            ticket.category.label(context),
          ].join(' · ')
        : '';

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.14),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.title,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (showStatusChip)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ticket.status.label(context),
                    style: AppTypography.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: AppSizes.spacingS),
            Text(
              meta,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
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

class _SurfaceSection extends StatelessWidget {
  final Widget child;

  const _SurfaceSection({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _UpdatesTimeline extends StatelessWidget {
  final List<TicketUpdateEntity> updates;

  const _UpdatesTimeline({required this.updates});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return Column(
      children: [
        for (var i = 0; i < updates.length; i++)
          _TimelineEntry(
            update: updates[i],
            locale: locale,
            isLast: i == updates.length - 1,
          ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final TicketUpdateEntity update;
  final String locale;
  final bool isLast;

  const _TimelineEntry({
    required this.update,
    required this.locale,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('d MMM yyyy, HH:mm', locale).format(update.createdAt);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSizes.spacingM,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      update.message,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingXS),
                    Text(
                      dateStr,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canChangeStatus(ticket.status) && nextStatuses.isNotEmpty) ...[
            Text(
              t.changeStatus,
              style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSizes.spacingM),
            Wrap(
              spacing: AppSizes.spacingS,
              runSpacing: AppSizes.spacingS,
              children: nextStatuses.map((s) {
                return ActionChip(
                  label: Text(s.label(context)),
                  onPressed: submitting
                      ? null
                      : () => onPatchStatus(ticket.id, s),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  labelStyle: AppTypography.body2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
            ),
          ],
          if (ticket.status == TicketStatus.closed) ...[
            const SizedBox(height: AppSizes.spacingS),
            Text(
              t.statusClosedHint,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.spacingL),
          Text(
            t.managerNote,
            style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSizes.spacingM),
          TextField(
            controller: noteController,
            maxLines: 4,
            enabled: noteEnabled,
            decoration: InputDecoration(
              hintText: noteEnabled ? t.managerNote : t.noteDisabledClosed,
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          SizedBox(
            height: AppSizes.buttonHeightSecondary,
            child: FilledButton.icon(
              onPressed: noteEnabled ? () => onAddNote(ticket.id) : null,
              icon: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.note_add_outlined),
              label: Text(t.addNote),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
