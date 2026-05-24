import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/ticket_entity.dart';
import '../utils/ticket_labels.dart';

class TicketListCard extends StatelessWidget {
  final TicketEntity ticket;
  final VoidCallback? onTap;
  final String? subtitlePrefix;
  /// Sakin listesi: daire/kategori satırı gizlenir.
  final bool showSubtitleMeta;
  final int descriptionMaxLines;

  const TicketListCard({
    super.key,
    required this.ticket,
    this.onTap,
    this.subtitlePrefix,
    this.showSubtitleMeta = true,
    this.descriptionMaxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(ticket.status);
    final date =
        '${ticket.createdAt.day}.${ticket.createdAt.month}.${ticket.createdAt.year}';
    final apt = ticket.apartmentNumber?.trim();
    final meta = showSubtitleMeta
        ? [
            if (subtitlePrefix != null && subtitlePrefix!.isNotEmpty)
              subtitlePrefix,
            if (apt != null && apt.isNotEmpty) apt,
            ticket.category.label(context),
          ].join(' · ')
        : '';

    return Material(
      color: AppColors.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _categoryIcon(ticket.category),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSizes.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ticket.title,
                              style: AppTypography.h4.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
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
                        const SizedBox(height: AppSizes.spacingXS),
                        Text(
                          meta,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSizes.spacingS),
                      Text(
                        ticket.description,
                        maxLines: descriptionMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingS),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: AppColors.textDisabled,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textDisabled,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textDisabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(TicketCategory category) {
    switch (category) {
      case TicketCategory.complaint:
        return Icons.report_problem_outlined;
      case TicketCategory.request:
        return Icons.handyman_outlined;
      case TicketCategory.malfunction:
        return Icons.build_circle_outlined;
      case TicketCategory.other:
        return Icons.more_horiz_rounded;
    }
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
