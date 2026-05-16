import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../data/apartments_store.dart';
import '../../domain/entities/apartment_entity.dart';

/// Daire silme onay dialog'u. Bina silmenin aksine tip-to-confirm yok;
/// daire silmek nispeten daha sık bir işlem ve daha az hasar vericidir.
/// FK varsa (sakin/aidat var) backend 400 döner ve mesajı insanlaştırırız.
class DeleteApartmentDialog extends ConsumerStatefulWidget {
  final ApartmentEntity apartment;

  const DeleteApartmentDialog({super.key, required this.apartment});

  static Future<bool?> show(
    BuildContext context, {
    required ApartmentEntity apartment,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteApartmentDialog(apartment: apartment),
    );
  }

  @override
  ConsumerState<DeleteApartmentDialog> createState() =>
      _DeleteApartmentDialogState();
}

class _DeleteApartmentDialogState extends ConsumerState<DeleteApartmentDialog> {
  bool _deleting = false;

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await ref
          .read(apartmentsStoreProvider(widget.apartment.buildingId).notifier)
          .removeApartment(widget.apartment.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ref.read(toastProvider.notifier).show(
            context.t.common.apartmentDeleted,
            type: ToastType.success,
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ref.read(toastProvider.notifier).show(
            _humanize(e),
            type: ToastType.error,
            duration: const Duration(seconds: 6),
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ref.read(toastProvider.notifier).show(
            context.t.common.apartmentDeleteFailed,
            type: ToastType.error,
          );
    }
  }

  String _humanize(ApiException e) {
    final raw = e.message.toLowerCase();
    if (raw.contains('foreign') ||
        raw.contains('p2003') ||
        raw.contains('still') ||
        raw.contains('resident') ||
        raw.contains('due')) {
      return context.t.common.apartmentDeleteFailedFK;
    }
    return e.message.isNotEmpty
        ? e.message
        : context.t.common.apartmentDeleteFailed;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.spacingS),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Text(
              context.t.common.deleteApartment,
              style: AppTypography.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.common.deleteApartmentConfirm,
            style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSizes.spacingM),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingM,
              vertical: AppSizes.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.door_front_door_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSizes.spacingS),
                Expanded(
                  child: Text(
                    widget.apartment.apartmentNumber,
                    style: AppTypography.body1.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: _deleting ? null : () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.borderColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size(48, 48),
          ),
          child: Text(
            context.t.common.cancelBtn,
            style: AppTypography.button.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _deleting ? null : _delete,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingL,
              vertical: AppSizes.spacingS,
            ),
          ),
          icon: _deleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.delete_outline, size: 20),
          label: Text(context.t.common.delete),
        ),
      ],
    );
  }
}
