import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../apartments/domain/entities/apartment_entity.dart';
import '../../utils/invite_code_helpers.dart';
import '../../../../l10n/strings.g.dart';

/// Dolu daireye yine de yeni kod üretilmek istendiğinde gösterilen onay dialogu.
class OccupiedApartmentConfirmDialog extends StatelessWidget {
  final ApartmentEntity apartment;
  final VoidCallback onConfirm;

  const OccupiedApartmentConfirmDialog({
    super.key,
    required this.apartment,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 8),
          Text(context.t.features.buildings.apartmentOccupied),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${InviteCodeHelpers.formatApartmentLabel(apartment.apartmentNumber)} dairesinde "${apartment.residentName}" kayıtlı.',
            style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text.rich(
            TextSpan(
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
              children: [
                TextSpan(text: context.t.features.buildings.newCodePrefix),
                TextSpan(
                  text: context.t.features.buildings.oldUserRemoved,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: context.t.common.confirmMessage),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSizes.spacingM,
        0,
        AppSizes.spacingM,
        AppSizes.spacingM,
      ),
      actions: [
        _DialogActionRow(
          confirmLabel: context.t.features.buildings.produceAnyway,
          confirmColor: AppColors.primary,
          onConfirm: () {
            Navigator.pop(context);
            onConfirm();
          },
        ),
      ],
    );
  }
}

/// Aktif kodu iptal etmek için onay dialogu.
class RevokeInviteCodeDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const RevokeInviteCodeDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.error),
          const SizedBox(width: 8),
          Text(context.t.features.buildings.cancelCode),
        ],
      ),
      content: Text.rich(
        TextSpan(
          style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          children: [
            TextSpan(text: context.t.features.buildings.currentCodePrefix),
            TextSpan(
              text: context.t.features.buildings.codeInvalid,
              style: AppTypography.body2.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: context.t.common.confirmMessage),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSizes.spacingM,
        0,
        AppSizes.spacingM,
        AppSizes.spacingM,
      ),
      actions: [
        _DialogActionRow(
          confirmLabel: context.t.features.buildings.cancelCode,
          confirmColor: AppColors.error,
          onConfirm: () {
            Navigator.pop(context);
            onConfirm();
          },
        ),
      ],
    );
  }
}

/// Vazgeç + onay butonlu yatay aksiyon satırı (dialoglarda kullanılır).
class _DialogActionRow extends StatelessWidget {
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const _DialogActionRow({
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: AppSizes.buttonHeightSecondary,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.borderColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                context.t.common.cancelBtn,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.spacingS),
        Expanded(
          child: SizedBox(
            height: AppSizes.buttonHeightSecondary,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onConfirm,
              child: Text(
                confirmLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
