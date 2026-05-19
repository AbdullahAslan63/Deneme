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
import '../providers/auth_provider.dart';

/// Tur 5 / §10/6 — Şifremi Unuttum ekranı.
///
/// Backend `POST /auth/forgot-password` her zaman 200 döner (enumeration leak
/// korumalı). UI kullanıcıya "kod gönderildi" mesajı verip reset ekranına
/// geçirir; kullanıcının kayıtlı olup olmadığını leak etmez.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final t = context.t;
    final key = InputValidators.validateEmail(value);
    if (key == null) return null;
    switch (key) {
      case 'email_required':
        return t.validation.emailRequired;
      case 'email_invalid':
        return t.validation.emailInvalid;
      case 'email_too_long':
        return t.validation.emailTooLong;
      default:
        return t.validation.emailRequired;
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final repo = ref.read(authRepositoryProvider);
    final email = _emailController.text.trim();

    try {
      await repo.forgotPassword(email);
      if (!mounted) return;

      ref.read(toastProvider.notifier).show(
            context.t.common.forgotPasswordSuccess,
            type: ToastType.success,
            duration: const Duration(seconds: 6),
          );

      // Reset ekranına email ön-doldurulmuş şekilde geç.
      context.push('/reset-password', extra: email);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Backend her zaman 200 döner ama yine de güvenlik ağı.
      ref.read(toastProvider.notifier).show(
            e.message.isNotEmpty
                ? e.message
                : context.t.features.auth.errorOccurred,
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
        title: Text(t.common.forgotPasswordTitle),
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
                    Icons.lock_reset,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingL),
                Text(
                  t.common.forgotPasswordTitle,
                  style: AppTypography.h2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spacingS),
                Text(
                  t.common.forgotPasswordSubtitle,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spacingXL),
                TextFormField(
                  controller: _emailController,
                  enabled: !_submitting,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: t.features.auth.email,
                    hintText: t.features.auth.emailHint,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.inputRadius),
                    ),
                  ),
                  validator: _validateEmail,
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
                      : Text(t.common.sendResetCode),
                ),
                const SizedBox(height: AppSizes.spacingM),
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeightSecondary,
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => context.push(
                              '/reset-password',
                              extra: _emailController.text.trim(),
                            ),
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
                      t.common.iHaveACode,
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
