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

/// Tur 5 / §3.1 — Sakini daireden çıkarma onay dialog'u.
///
/// Daire silmeden farklı: sakin hesabı SİLİNMEZ; sadece daire ile
/// bağlantısı kopar. Aidat geçmişi de korunur. Bu yüzden tip-to-confirm
/// gerektirmiyoruz, basit AlertDialog yeterli.
class RemoveResidentDialog extends ConsumerStatefulWidget {
  final ApartmentEntity apartment;

  const RemoveResidentDialog({super.key, required this.apartment});

  static Future<bool?> show(
    BuildContext context, {
    required ApartmentEntity apartment,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RemoveResidentDialog(apartment: apartment),
    );
  }

  @override
  ConsumerState<RemoveResidentDialog> createState() =>
      _RemoveResidentDialogState();
}

class _RemoveResidentDialogState extends ConsumerState<RemoveResidentDialog> {
  bool _removing = false;

  Future<void> _remove() async {
    setState(() => _removing = true);
    try {
      await ref
          .read(apartmentsStoreProvider(widget.apartment.buildingId).notifier)
          .removeResidentFromApartment(widget.apartment.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ref.read(toastProvider.notifier).show(
            context.t.common.residentRemoved,
            type: ToastType.success,
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _removing = false);
      ref.read(toastProvider.notifier).show(
            _humanize(e),
            type: ToastType.error,
            duration: const Duration(seconds: 6),
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _removing = false);
      ref.read(toastProvider.notifier).show(
            context.t.common.residentRemoveFailed,
            type: ToastType.error,
          );
    }
  }

  /// Backend olası 403/404 mesajları:
  ///  - 403: bu binayı sen yönetmiyorsun
  ///  - 404: daire / sakin yok
  String _humanize(ApiException e) {
    final raw = e.message.toLowerCase();
    if (raw.contains('forbidden') ||
        raw.contains('not the manager') ||
        raw.contains('yetk')) {
      return context.t.common.residentRemoveForbidden;
    }
    if (raw.contains('not found') ||
        raw.contains('no resident') ||
        raw.contains('bulunam')) {
      return context.t.common.residentRemoveNotFound;
    }
    return e.message.isNotEmpty
        ? e.message
        : context.t.common.residentRemoveFailed;
  }

  @override
  Widget build(BuildContext context) {
    final residentName = widget.apartment.resident?.name ?? '';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.spacingS),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_remove_outlined,
              color: AppColors.warning,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Text(
              context.t.common.removeResident,
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
            context.t.common.removeResidentConfirm,
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
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSizes.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        residentName,
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.apartment.apartmentNumber,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          Container(
            padding: const EdgeInsets.all(AppSizes.spacingM),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 18,
                ),
                const SizedBox(width: AppSizes.spacingS),
                Expanded(
                  child: Text(
                    context.t.common.removeResidentNote,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
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
          onPressed: _removing ? null : () => Navigator.of(context).pop(false),
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
          onPressed: _removing ? null : _remove,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingL,
              vertical: AppSizes.spacingS,
            ),
          ),
          icon: _removing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.person_remove_outlined, size: 20),
          label: Text(context.t.common.remove),
        ),
      ],
    );
  }
}
