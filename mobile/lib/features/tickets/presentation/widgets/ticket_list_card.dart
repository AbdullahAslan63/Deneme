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

  const TicketListCard({
    super.key,
    required this.ticket,
    this.onTap,
    this.subtitlePrefix,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(ticket.status);
    final date =
        '${ticket.createdAt.day}.${ticket.createdAt.month}.${ticket.createdAt.year}';
    final apt = ticket.apartmentNumber?.trim();
    final meta = [
      if (subtitlePrefix != null && subtitlePrefix!.isNotEmpty) subtitlePrefix,
      if (apt != null && apt.isNotEmpty) apt,
      ticket.category.label(context),
    ].join(' · ');

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            if (meta.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacingXS),
              Text(
                meta,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
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
