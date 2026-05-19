import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../data/buildings_store.dart';
import '../../domain/entities/building_entity.dart';

/// Bina silmek için tip-to-confirm dialog'u.
/// Kullanıcı, bina adını aynen yazana kadar "Sil" butonu pasiftir.
/// Belge §5: DELETE /buildings/:id; FK varsa 400 döner, mesajı
/// kullanıcı dostu Türkçeye çeviriyoruz.
class DeleteBuildingDialog extends ConsumerStatefulWidget {
  final BuildingEntity building;

  const DeleteBuildingDialog({super.key, required this.building});

  /// `true` döner: silindi; `false`/`null`: iptal veya hata.
  static Future<bool?> show(
    BuildContext context, {
    required BuildingEntity building,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteBuildingDialog(building: building),
    );
  }

  @override
  ConsumerState<DeleteBuildingDialog> createState() =>
      _DeleteBuildingDialogState();
}

class _DeleteBuildingDialogState extends ConsumerState<DeleteBuildingDialog> {
  final _controller = TextEditingController();
  bool _deleting = false;
  bool _attempted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _matches => _controller.text.trim() == widget.building.name.trim();

  Future<void> _delete() async {
    if (!_matches) {
      setState(() => _attempted = true);
      return;
    }
    setState(() => _deleting = true);
    try {
      await ref.read(buildingsStoreProvider.notifier).removeBuilding(
            widget.building.id,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ref.read(toastProvider.notifier).show(
            context.t.common.buildingDeleted,
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
            context.t.common.buildingDeleteFailed,
            type: ToastType.error,
          );
    }
  }

  String _humanize(ApiException e) {
    final raw = e.message.toLowerCase();
    // Backend FK ihlalini birden fazla şekilde dönebilir
    // (Prisma P2003, "still has", "foreign key", vs.)
    if (raw.contains('foreign') ||
        raw.contains('p2003') ||
        raw.contains('still') ||
        raw.contains('apartment') ||
        raw.contains('resident') ||
        raw.contains('due')) {
      return context.t.common.buildingDeleteFailedFK;
    }
    return e.message.isNotEmpty
        ? e.message
        : context.t.common.buildingDeleteFailed;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        AppSizes.spacingL,
        AppSizes.spacingL,
        AppSizes.spacingL,
        AppSizes.spacingS,
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
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Text(
              context.t.common.deleteBuilding,
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
            context.t.common.deleteBuildingHeader,
            style: AppTypography.body1.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          Text(
            context.t.common.deleteBuildingTypeHint,
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.spacingS),
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
            child: SelectableText(
              widget.building.name,
              style: AppTypography.body1.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: context.t.common.deleteBuildingTypeFieldLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              ),
              errorText: _attempted && !_matches
                  ? context.t.common.buildingNameMismatch
                  : null,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSizes.spacingL,
        0,
        AppSizes.spacingL,
        AppSizes.spacingM,
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
          onPressed: (_deleting || !_matches) ? null : _delete,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppColors.error.withValues(alpha: 0.35),
            disabledForegroundColor: Colors.white,
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
