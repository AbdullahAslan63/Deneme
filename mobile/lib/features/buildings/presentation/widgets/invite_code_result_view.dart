import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../apartments/domain/entities/apartment_entity.dart';
import '../../domain/entities/building_entity.dart';
import '../../utils/invite_code_helpers.dart';
import '../../../../l10n/strings.g.dart';

/// Adım 3: Üretilen davet kodunu gösteren ve aksiyonları sunan görünüm.
class InviteCodeResultView extends StatelessWidget {
  final String code;
  final BuildingEntity building;
  final ApartmentEntity apartment;
  final DateTime expiresAt;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onRevoke;
  final VoidCallback onPickAnother;
  final VoidCallback onGoHome;

  const InviteCodeResultView({
    super.key,
    required this.code,
    required this.building,
    required this.apartment,
    required this.expiresAt,
    required this.onCopy,
    required this.onShare,
    required this.onRevoke,
    required this.onPickAnother,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = expiresAt.difference(DateTime.now());
    final items = <Widget>[
      _buildSuccessBanner(context),
      const SizedBox(height: AppSizes.spacingL),
      _buildCodeCard(context, remaining),
      const SizedBox(height: AppSizes.spacingL),
      _buildPrimaryActions(context),
      const SizedBox(height: AppSizes.spacingM),
      _buildInfoNote(context),
      const SizedBox(height: AppSizes.spacingM),
      _buildSecondaryActions(context),
      const SizedBox(height: AppSizes.spacingL),
      _buildHomeButton(context),
    ];
    return ListView.builder(
      key: const ValueKey('step-2'),
      padding: AppSizes.screenBodyScrollPadding,
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  Widget _buildSuccessBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingM,
        vertical: AppSizes.spacingL,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.success, AppColors.successLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          Text(
            context.t.features.buildings.codeReady,
            style: AppTypography.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${building.name} • ${InviteCodeHelpers.formatApartmentLabel(apartment.apartmentNumber)}',
            style: AppTypography.body2.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard(BuildContext context, Duration remaining) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingM,
        vertical: AppSizes.spacingL,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Text(
            context.t.features.buildings.code,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.spacingS),
          SelectableText(
            code,
            style: AppTypography.h1.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spacingM),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingM,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                Text(
                  context.t.features.buildings.validFor7Days,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            '${context.t.common.expiresAtPrefix}: ${InviteCodeHelpers.formatDate(expiresAt)}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '${context.t.common.remainingPrefix}: ${InviteCodeHelpers.remainingText(remaining)}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: AppSizes.buttonHeightPrimary,
            child: ElevatedButton.icon(
              onPressed: onCopy,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.copy),
              label: Text(context.t.features.buildings.copy),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.spacingM),
        Expanded(
          child: SizedBox(
            height: AppSizes.buttonHeightPrimary,
            child: OutlinedButton.icon(
              onPressed: onShare,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.share),
              label: Text(context.t.features.buildings.share),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.t.features.buildings.activeCodeNote,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: AppSizes.buttonHeightSecondary,
            child: OutlinedButton.icon(
              onPressed: onPickAnother,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.borderColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.list_alt),
              label: Text(context.t.features.buildings.anotherApartment),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.spacingS),
        Expanded(
          child: SizedBox(
            height: AppSizes.buttonHeightSecondary,
            child: OutlinedButton.icon(
              onPressed: onRevoke,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: Text(context.t.features.buildings.cancelCode),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return SizedBox(
      height: AppSizes.buttonHeightPrimary,
      child: ElevatedButton.icon(
        onPressed: onGoHome,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.home),
        label: Text(
          context.t.features.buildings.backToMainMenu,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
