import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../domain/entities/ticket_entity.dart';

/// Sakin talep detayı — yatay durum izleyici (Trendyol kargo tarzı).
class TicketStatusStepper extends StatelessWidget {
  final TicketStatus currentStatus;

  const TicketStatusStepper({super.key, required this.currentStatus});

  static const _steps = [
    TicketStatus.open,
    TicketStatus.inProgress,
    TicketStatus.resolved,
    TicketStatus.closed,
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.t.features.tickets;
    final currentIndex = _steps.indexOf(currentStatus);
    final headline = _headline(context, currentStatus);
    final headlineColor = _headlineColor(currentStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                t.statusTrackerTitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: AppTypography.h4.copyWith(
              color: headlineColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.spacingL),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _steps.length; i++)
                Expanded(
                  child: _StepColumn(
                    stepIndex: i,
                    displayNumber: i + 1,
                    label: _stepLabel(context, _steps[i]),
                    icon: _stepIcon(_steps[i]),
                    isFirst: i == 0,
                    isLast: i == _steps.length - 1,
                    currentIndex: currentIndex,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _headline(BuildContext context, TicketStatus status) {
    final t = context.t.features.tickets;
    switch (status) {
      case TicketStatus.open:
        return t.statusHeadlineOpen;
      case TicketStatus.inProgress:
        return t.statusHeadlineInProgress;
      case TicketStatus.resolved:
        return t.statusHeadlineResolved;
      case TicketStatus.closed:
        return t.statusHeadlineClosed;
    }
  }

  Color _headlineColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return AppColors.warning;
      case TicketStatus.inProgress:
        return AppColors.accent;
      case TicketStatus.resolved:
      case TicketStatus.closed:
        return AppColors.success;
    }
  }

  String _stepLabel(BuildContext context, TicketStatus status) {
    final t = context.t.features.tickets;
    switch (status) {
      case TicketStatus.open:
        return t.statusStepWaiting;
      case TicketStatus.inProgress:
        return t.statusStepInProgress;
      case TicketStatus.resolved:
        return t.statusStepResolved;
      case TicketStatus.closed:
        return t.statusStepClosed;
    }
  }

  IconData _stepIcon(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Icons.hourglass_top_rounded;
      case TicketStatus.inProgress:
        return Icons.autorenew_rounded;
      case TicketStatus.resolved:
        return Icons.task_alt_rounded;
      case TicketStatus.closed:
        return Icons.inventory_2_rounded;
    }
  }
}

enum _StepVisualState { completed, active, pending }

class _StepColumn extends StatelessWidget {
  final int stepIndex;
  final int displayNumber;
  final String label;
  final IconData icon;
  final bool isFirst;
  final bool isLast;
  final int currentIndex;

  const _StepColumn({
    required this.stepIndex,
    required this.displayNumber,
    required this.label,
    required this.icon,
    required this.isFirst,
    required this.isLast,
    required this.currentIndex,
  });

  _StepVisualState get _state {
    if (stepIndex < currentIndex) return _StepVisualState.completed;
    if (stepIndex == currentIndex) return _StepVisualState.active;
    return _StepVisualState.pending;
  }

  Color get _circleColor {
    if (_state == _StepVisualState.pending) return AppColors.background;
    if (_state == _StepVisualState.active) {
      if (stepIndex >= 2) return AppColors.success;
      return AppColors.accent;
    }
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final circleColor = _circleColor;
    final iconColor = state == _StepVisualState.pending
        ? AppColors.textDisabled
        : Colors.white;
    final borderColor =
        state == _StepVisualState.pending ? AppColors.border : circleColor;

    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isFirst)
                Expanded(
                  child: Container(
                    height: 3,
                    color: _lineColorForLeftSegment(),
                  ),
                ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 22),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 3,
                    color: _lineColorForRightSegment(),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.spacingS),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            '$displayNumber. $label',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: state == _StepVisualState.pending
                  ? AppColors.textDisabled
                  : AppColors.textPrimary,
              fontWeight:
                  state == _StepVisualState.active ? FontWeight.w800 : FontWeight.w600,
              height: 1.2,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Color _lineColorForLeftSegment() {
    return stepIndex <= currentIndex ? AppColors.accent : AppColors.border;
  }

  Color _lineColorForRightSegment() {
    return stepIndex < currentIndex ? AppColors.accent : AppColors.border;
  }
}
