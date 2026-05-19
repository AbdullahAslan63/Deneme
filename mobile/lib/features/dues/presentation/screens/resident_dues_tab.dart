import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../domain/entities/due_entity.dart';
import '../providers/dues_provider.dart';

class ResidentDuesTab extends ConsumerStatefulWidget {
  const ResidentDuesTab({super.key});

  @override
  ConsumerState<ResidentDuesTab> createState() => _ResidentDuesTabState();
}

class _ResidentDuesTabState extends ConsumerState<ResidentDuesTab> {
  bool _requested = false;

  @override
  Widget build(BuildContext context) {
    final duesState = ref.watch(duesNotifierProvider);

    if (!_requested) {
      _requested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(duesNotifierProvider.notifier).loadMyDues();
      });
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(duesNotifierProvider.notifier).loadMyDues(),
      child: ListView.builder(
        padding: AppSizes.screenBodyScrollPadding,
        itemCount: duesState.isLoading
            ? 1
            : duesState.dues.isEmpty
                ? 1
                : duesState.dues.length + 1,
        itemBuilder: (context, index) {
          if (duesState.isLoading) {
            return const Padding(
              padding: EdgeInsets.only(top: AppSizes.spacingXL),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (duesState.dues.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: AppSizes.spacingXL),
              child: Center(
                child: Text(
                  context.t.common.noDuesYet,
                  style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
                ),
              ),
            );
          }

          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
              child: Text(
                context.t.common.myDuesHistory,
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
            );
          }

          final due = duesState.dues[index - 1];
          return _buildDueCard(context, due);
        },
      ),
    );
  }

  Widget _buildDueCard(BuildContext context, DueEntity due) {
    final statusVisual = _statusVisual(context, due.status);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingM),
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
            children: [
              Expanded(
                child: Text(
                  due.apartmentNumber,
                  style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusVisual.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusVisual.label,
                  style: AppTypography.caption.copyWith(
                    color: statusVisual.fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            '₺${due.amount.toStringAsFixed(2)}',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            '${context.t.common.month}: ${due.month} • ${context.t.common.year}: ${due.year}',
            style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  _StatusVisual _statusVisual(BuildContext context, DueStatus status) {
    switch (status) {
      case DueStatus.paid:
        return _StatusVisual(
          label: context.t.common.paidStatus,
          fg: AppColors.success,
          bg: AppColors.successBg,
        );
      case DueStatus.overdue:
        return _StatusVisual(
          label: context.t.common.overdueStatus,
          fg: AppColors.error,
          bg: AppColors.errorBg,
        );
      case DueStatus.waived:
        return _StatusVisual(
          label: context.t.common.waivedStatus,
          fg: AppColors.textSecondary,
          bg: AppColors.borderColor,
        );
      case DueStatus.pending:
        return _StatusVisual(
          label: context.t.common.pendingStatus,
          fg: AppColors.warning,
          bg: AppColors.warningBg,
        );
    }
  }
}

class _StatusVisual {
  final String label;
  final Color fg;
  final Color bg;

  const _StatusVisual({
    required this.label,
    required this.fg,
    required this.bg,
  });
}
