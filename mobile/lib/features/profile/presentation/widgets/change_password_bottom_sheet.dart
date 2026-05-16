import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// Tur 5 / §10/4 — Şifre Değiştir bottom sheet.
///
/// Backend `PUT /me/password` başarısı sonrası `refreshTokenVersion++`
/// uyguluyor → mevcut refresh token geçersiz olur. UX:
///   1. Başarı toast (çok dikkat çekici, 5 sn)
///   2. Yerel oturumu kapat (logout())
///   3. `/login` ekranına yönlendir
class ChangePasswordBottomSheet extends ConsumerStatefulWidget {
  const ChangePasswordBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChangePasswordBottomSheet(),
    );
  }

  @override
  ConsumerState<ChangePasswordBottomSheet> createState() =>
      _ChangePasswordBottomSheetState();
}

class _ChangePasswordBottomSheetState
    extends ConsumerState<ChangePasswordBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  String? _validateNewPassword(String? value) {
    final t = context.t;
    final key = InputValidators.validatePassword(value);
    if (key == null) {
      // Yeni şifre eski ile aynı olamaz
      if (value != null && value == _currentPwController.text) {
        return t.common.passwordsMustDiffer;
      }
      return null;
    }
    switch (key) {
      case 'password_required':
        return t.validation.passwordRequired;
      case 'password_too_short':
        return t.validation.passwordTooShort;
      case 'password_too_long':
        return t.validation.passwordTooLong;
      case 'password_uppercase_required':
        return t.validation.passwordUppercaseRequired;
      case 'password_lowercase_required':
        return t.validation.passwordLowercaseRequired;
      case 'password_number_required':
        return t.validation.passwordNumberRequired;
      case 'password_special_char_required':
        return t.validation.passwordSpecialCharRequired;
      default:
        return t.validation.passwordRequired;
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final repo = ref.read(profileRepositoryProvider);
    // Sheet pop sonrası context geçersizleşeceği için global nesneleri
    // önceden yakala (use_build_context_synchronously uyarısı için).
    final navigator = Navigator.of(context);
    final goRouter = GoRouter.of(context);
    final toast = ref.read(toastProvider.notifier);
    final successMsg = context.t.common.changePasswordSuccess;

    try {
      await repo.changePassword(
        currentPassword: _currentPwController.text,
        newPassword: _newPwController.text,
      );

      if (!mounted) return;
      navigator.pop();

      toast.show(
        successMsg,
        type: ToastType.success,
        duration: const Duration(seconds: 5),
      );

      await ref.read(authStateProvider.notifier).logout(ref);
      goRouter.go('/login');
    } on ApiException catch (e) {
      if (!mounted) return;
      // 401 / "current password incorrect" → özel mesaj
      final msg = (e.statusCode == 401 ||
              e.message.toLowerCase().contains('current password'))
          ? context.t.common.changePasswordWrongCurrent
          : (e.message.isNotEmpty
              ? e.message
              : context.t.common.changePasswordFailed);
      ref.read(toastProvider.notifier).show(msg, type: ToastType.error);
      setState(() => _submitting = false);
    } catch (_) {
      if (!mounted) return;
      ref.read(toastProvider.notifier).show(
            context.t.common.changePasswordFailed,
            type: ToastType.error,
          );
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_submitting,
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSizes.spacingL,
            AppSizes.spacingS,
            AppSizes.spacingL,
            AppSizes.spacingL + MediaQuery.of(context).padding.bottom,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.common.changePasswordTitle,
                              style: AppTypography.h3,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.common.changePasswordSubtitle,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                  TextFormField(
                    controller: _currentPwController,
                    obscureText: _obscureCurrent,
                    enabled: !_submitting,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: t.common.currentPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrent
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(
                            () => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return t.common.currentPasswordRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  TextFormField(
                    controller: _newPwController,
                    obscureText: _obscureNew,
                    enabled: !_submitting,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: t.common.newPassword,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: _validateNewPassword,
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  TextFormField(
                    controller: _confirmPwController,
                    obscureText: _obscureConfirm,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: t.common.newPasswordConfirm,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return t.features.auth.confirmPassword;
                      }
                      if (value != _newPwController.text) {
                        return t.features.auth.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppSizes.buttonHeightSecondary,
                          child: OutlinedButton(
                            onPressed: _submitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(
                                color: AppColors.borderColor,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              t.common.cancelBtn,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingM),
                      Expanded(
                        child: SizedBox(
                          height: AppSizes.buttonHeightSecondary,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.buttonRadius,
                                ),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(t.common.changePasswordTitle),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
