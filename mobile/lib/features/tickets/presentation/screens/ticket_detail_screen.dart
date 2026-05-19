import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(ticketDetailProvider(widget.ticketId));
    final isManager =
        ref.watch(authStateProvider).user?.role == UserRole.manager;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.features.tickets.detailTitle),
        centerTitle: true,
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (ticket) => ListView(
          padding: AppSizes.screenBodyScrollPadding,
          children: [
            Text(ticket.title,
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSizes.spacingS),
            Text(ticket.category.label(context),
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSizes.spacingM),
            Text(ticket.description,
                style: AppTypography.body1
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSizes.spacingM),
            Text('${context.t.features.tickets.statusLabel}: ${ticket.status.label(context)}',
                style: AppTypography.body2),
            if (ticket.updates.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacingL),
              Text(context.t.features.tickets.updatesTitle,
                  style: AppTypography.h4),
              const SizedBox(height: AppSizes.spacingS),
              ...ticket.updates.map(
                (u) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spacingS),
                  child: Text('• ${u.message}',
                      style: AppTypography.body2
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ),
            ],
            if (isManager) ...[
              const SizedBox(height: AppSizes.spacingL),
              Text(context.t.features.tickets.changeStatus,
                  style: AppTypography.h4),
              const SizedBox(height: AppSizes.spacingS),
              Wrap(
                spacing: 8,
                children: TicketStatus.values.map((s) {
                  return ActionChip(
                    label: Text(s.label(context)),
                    onPressed: _submitting
                        ? null
                        : () => _patchStatus(ticket.id, s),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.spacingL),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.t.features.tickets.managerNote,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.spacingM),
              FilledButton(
                onPressed: _submitting ? null : () => _addNote(ticket.id),
                child: Text(context.t.features.tickets.addNote),
              ),
            ],
          ],
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
