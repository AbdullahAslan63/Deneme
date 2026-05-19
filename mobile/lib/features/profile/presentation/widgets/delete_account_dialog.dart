import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// Tur 5 / §10/5 — Hesabı Kapat (KVKK soft delete) tip-to-confirm dialog.
///
/// Backend `DELETE /me` davranışı (commit 8cc2152):
///   - 200: Soft delete, PII maskelendi, refreshTokenVersion++
///   - 409: Yöneticide bina var → "Önce binaları sil/devret"
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountDialog(),
    );
  }

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _deleting = false;
  bool _attempted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(String confirmPhrase) =>
      _controller.text.trim().toUpperCase() == confirmPhrase.toUpperCase();

  Future<void> _delete(String confirmPhrase) async {
    if (!_matches(confirmPhrase)) {
      setState(() => _attempted = true);
      return;
    }
    setState(() => _deleting = true);

    final repo = ref.read(profileRepositoryProvider);
    // Dialog pop sonrası context geçersizleşeceği için global nesneleri
    // önceden yakala (use_build_context_synchronously uyarısı için).
    final navigator = Navigator.of(context);
    final goRouter = GoRouter.of(context);
    final toast = ref.read(toastProvider.notifier);
    final successMsg = context.t.common.deleteAccountSuccess;

    try {
      await repo.deleteAccount();
      if (!mounted) return;
      navigator.pop(true);

      toast.show(
        successMsg,
        type: ToastType.success,
        duration: const Duration(seconds: 5),
      );

      await ref.read(authStateProvider.notifier).logout(ref);
      goRouter.go('/login');
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
            context.t.common.deleteAccountFailed,
            type: ToastType.error,
          );
    }
  }

  String _humanize(ApiException e) {
    final raw = e.message.toLowerCase();
    if (e.statusCode == 409 ||
        raw.contains('manage') ||
        raw.contains('building') ||
        raw.contains('bina')) {
      return context.t.common.deleteAccountFailedManager;
    }
    return e.message.isNotEmpty
        ? e.message
        : context.t.common.deleteAccountFailed;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final confirmPhrase = t.common.deleteAccountTypePhrase;

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
              t.common.deleteAccountTitle,
              style: AppTypography.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.common.deleteAccountWarning,
              style:
                  AppTypography.body2.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.spacingM),
            Text(
              t.common.deleteAccountTypeHint,
              style:
                  AppTypography.body2.copyWith(color: AppColors.textSecondary),
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
                confirmPhrase,
                style: AppTypography.body1.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacingM),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                labelText: confirmPhrase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                ),
                errorText: _attempted && !_matches(confirmPhrase)
                    ? t.common.deleteAccountTypeMismatch
                    : null,
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSizes.spacingL,
        AppSizes.spacingM,
        AppSizes.spacingL,
        AppSizes.spacingL,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: AppSizes.buttonHeightSecondary,
                child: OutlinedButton(
                  onPressed: _deleting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(
                      color: AppColors.borderColor,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.buttonRadius,
                      ),
                    ),
                  ),
                  child: Text(
                    t.common.cancelBtn,
                    style: AppTypography.button.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingM),
              SizedBox(
                height: AppSizes.buttonHeightSecondary,
                child: ElevatedButton.icon(
                  onPressed: (_deleting || !_matches(confirmPhrase))
                      ? null
                      : () => _delete(confirmPhrase),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.error.withValues(alpha: 0.35),
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacingM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.buttonRadius,
                      ),
                    ),
                  ),
                  icon: _deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.delete_forever, size: 22),
                  label: Text(
                    t.common.deleteAccountConfirmButton,
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
