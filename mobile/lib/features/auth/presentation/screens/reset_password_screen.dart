import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../providers/auth_provider.dart';

/// Tur 5 / §10/6 — Şifre Sıfırlama ekranı.
///
/// Backend kabul ettiği token alfabesi (Crockford Base32 türevi):
/// `23456789ABCDEFGHJKLMNPQRSTUVWXYZ` (uzunluk 6, trim + büyük harfe çevirir).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  /// İsteğe bağlı: forgot ekranından gelen email — bilgi amaçlı gösterilebilir.
  final String? prefilledEmail;

  const ResetPasswordScreen({super.key, this.prefilledEmail});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  static final _resetCodeAlphabet =
      RegExp(r'^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{6}$');
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  String? _validateNewPassword(String? value) {
    final t = context.t;
    final key = InputValidators.validatePassword(value);
    if (key == null) return null;
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
    final repo = ref.read(authRepositoryProvider);

    try {
      await repo.resetPassword(
        _codeController.text.trim().toUpperCase(),
        _newPwController.text,
      );
      if (!mounted) return;

      ref.read(toastProvider.notifier).show(
            context.t.common.resetPasswordSuccess,
            type: ToastType.success,
            duration: const Duration(seconds: 5),
          );
      context.go('/login');
    } on ApiException catch (e) {
      if (!mounted) return;
      // Backend 400 = invalid/expired token; mesajı insanlaştır.
      final isInvalid = e.statusCode == 400 ||
          e.message.toLowerCase().contains('token') ||
          e.message.toLowerCase().contains('expired');
      ref.read(toastProvider.notifier).show(
            isInvalid
                ? context.t.common.resetPasswordFailed
                : (e.message.isNotEmpty
                    ? e.message
                    : context.t.common.resetPasswordFailed),
            type: ToastType.error,
            duration: const Duration(seconds: 6),
          );
    } catch (_) {
      if (!mounted) return;
      ref.read(toastProvider.notifier).show(
            context.t.common.resetPasswordFailed,
            type: ToastType.error,
          );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.common.resetPasswordTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.screenBodyScrollPadding,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  margin: const EdgeInsets.only(top: AppSizes.spacingL),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.password_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingL),
                Text(
                  t.common.resetPasswordTitle,
                  style: AppTypography.h2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spacingS),
                Text(
                  t.common.resetPasswordSubtitle,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.prefilledEmail != null &&
                    widget.prefilledEmail!.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.spacingS),
                  Text(
                    widget.prefilledEmail!,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSizes.spacingXL),
                TextFormField(
                  controller: _codeController,
                  enabled: !_submitting,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  maxLength: 6,
                  inputFormatters: [
                    // Backend alfabesi dışı karakterleri filtrele.
                    FilteringTextInputFormatter.allow(
                      RegExp('[23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjklmnpqrstuvwxyz]'),
                    ),
                  ],
                  style: AppTypography.h3.copyWith(
                    letterSpacing: 6,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: t.common.resetCode,
                    hintText: t.common.resetCodeHint,
                    counterText: '',
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.inputRadius),
                    ),
                  ),
                  validator: (value) {
                    final v = (value ?? '').trim().toUpperCase();
                    if (v.isEmpty) return t.common.resetCodeRequired;
                    if (!_resetCodeAlphabet.hasMatch(v)) {
                      return t.common.resetCodeInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.spacingM),
                TextFormField(
                  controller: _newPwController,
                  enabled: !_submitting,
                  obscureText: _obscureNew,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: t.common.newPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.inputRadius),
                    ),
                  ),
                  validator: _validateNewPassword,
                ),
                const SizedBox(height: AppSizes.spacingM),
                TextFormField(
                  controller: _confirmPwController,
                  enabled: !_submitting,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: t.common.newPasswordConfirm,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.inputRadius),
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
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      AppSizes.buttonHeightPrimary,
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(t.common.resetPasswordSubmit),
                ),
                const SizedBox(height: AppSizes.spacingM),
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeightSecondary,
                  child: OutlinedButton(
                    onPressed:
                        _submitting ? null : () => context.go('/login'),
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
                      t.common.backToLogin,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
