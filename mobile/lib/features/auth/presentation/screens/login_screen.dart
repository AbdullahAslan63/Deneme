import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/platform/system_navigator_bridge.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/alt_action_button.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late TextEditingController _identifierController;
  late TextEditingController _passwordController;
  late FocusNode _identifierFocusNode;
  // Identifier "next" tuşundan sonra şifreye odaklanmak için.
  late FocusNode _passwordFocusNode;
  bool _obscurePassword = true;
  bool _usePhoneLogin = false;

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController();
    _passwordController = TextEditingController();
    _identifierFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _toggleLoginMode() {
    _identifierFocusNode.unfocus();
    setState(() {
      _usePhoneLogin = !_usePhoneLogin;
      _identifierController.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _identifierFocusNode.requestFocus();
    });
  }

  void _handleLogin(BuildContext context) {
    if (ref.read(authStateProvider).isLoading) return;
    final raw = _identifierController.text.trim();
    final password = _passwordController.text;

    // Input validation
    String? identifierError;
    String? passwordError;

    if (_usePhoneLogin) {
      final phoneError = InputValidators.validatePhone(raw);
      identifierError = phoneError == null
          ? null
          : phoneError == 'phone_required'
          ? context.t.validation.phoneRequired
          : context.t.validation.phoneInvalid;
    } else {
      final emailError = InputValidators.validateEmail(raw);
      identifierError = emailError == null
          ? null
          : emailError == 'email_required'
          ? context.t.validation.emailRequired
          : emailError == 'email_invalid'
          ? context.t.validation.emailInvalid
          : context.t.validation.emailTooLong;
    }

    passwordError = password.isEmpty
        ? context.t.features.auth.passwordRequired
        : null;

    // Show validation errors
    if (identifierError != null || passwordError != null) {
      String errorMessage = '';
      if (identifierError != null) {
        errorMessage += identifierError;
      }
      if (passwordError != null) {
        if (errorMessage.isNotEmpty) errorMessage += '\n';
        errorMessage += passwordError;
      }

      ref
          .read(toastProvider.notifier)
          .show(errorMessage, type: ToastType.error);
      return;
    }

    final identifier = _usePhoneLogin ? '+90$raw' : raw;
    ref.read(authStateProvider.notifier).login(identifier, password, ref);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (previous, next) {
      if (next.isAuthenticated &&
          next.user != null &&
          !(previous?.isAuthenticated ?? false)) {
        ref.read(toastProvider.notifier).show(
              context.t.features.auth.loginSuccess,
              type: ToastType.success,
              duration: const Duration(seconds: 4),
            );
      }
      if (next.error != null && next.error != previous?.error) {
        ref
            .read(toastProvider.notifier)
            .show(
              next.error ?? context.t.features.auth.errorOccurred,
              type: ToastType.error,
            );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
          return;
        }
        await SystemNavigatorBridge.moveAppToBackground();
      },
      child: Scaffold(
        body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingFieldSpacing),
                    Text(
                      context.t.features.auth.appTitle,
                      style: AppTypography.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingXS),
                    Text(
                      context.t.features.auth.appSubtitle,
                      style: AppTypography.body2.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: AppSizes.screenBodyScrollPadding,
                    // Kullanıcı listeyi sürüklerse klavye otomatik kapansın.
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.t.features.auth.login,
                          style: AppTypography.h2.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingL),
                        TextField(
                          key: ValueKey(_usePhoneLogin ? 'phone' : 'email'),
                          controller: _identifierController,
                          focusNode: _identifierFocusNode,
                          enabled: !authState.isLoading,
                          keyboardType: _usePhoneLogin
                              ? TextInputType.phone
                              : TextInputType.emailAddress,
                          maxLength: _usePhoneLogin ? 10 : null,
                          inputFormatters: _usePhoneLogin
                              ? [FilteringTextInputFormatter.digitsOnly]
                              : null,
                          textInputAction: TextInputAction.next,
                          // Identifier alanı dolduktan sonra "next" ile
                          // şifre alanına otomatik odaklan.
                          onSubmitted: (_) =>
                              _passwordFocusNode.requestFocus(),
                          autofillHints: _usePhoneLogin
                              ? const [AutofillHints.telephoneNumberNational]
                              : const [AutofillHints.username,
                                  AutofillHints.email],
                          style: AppTypography.body1,
                          decoration: InputDecoration(
                            labelText: _usePhoneLogin
                                ? context.t.features.auth.phone
                                : context.t.features.auth.email,
                            hintText: _usePhoneLogin
                                ? context.t.features.auth.phoneHint
                                : context.t.features.auth.emailHint,
                            prefixText: _usePhoneLogin ? '+90 ' : null,
                            prefixIcon: Icon(
                              _usePhoneLogin
                                  ? Icons.phone_outlined
                                  : Icons.email_outlined,
                              size: AppSizes.iconSize,
                            ),
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.spacingM,
                              vertical: AppSizes.spacingM,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.inputRadius,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingFieldSpacing),
                        TextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          enabled: !authState.isLoading,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          // Şifre tamamlandığında klavyeden direkt giriş.
                          onSubmitted: (_) => _handleLogin(context),
                          autofillHints: const [AutofillHints.password],
                          style: AppTypography.body1,
                          decoration: InputDecoration(
                            labelText: context.t.features.auth.password,
                            hintText: context.t.features.auth.passwordHint,
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              size: AppSizes.iconSize,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: AppSizes.iconSize,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                              iconSize: AppSizes.iconTouchTarget,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.spacingM,
                              vertical: AppSizes.spacingM,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.inputRadius,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingFieldSpacing),
                        ElevatedButton(
                          onPressed: authState.isLoading
                              ? null
                              : () => _handleLogin(context),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(context.t.features.auth.login),
                        ),
                        const SizedBox(height: AppSizes.spacingXS),
                        OutlinedButton.icon(
                          onPressed: authState.isLoading
                              ? null
                              : _toggleLoginMode,
                          icon: Icon(
                            _usePhoneLogin
                                ? Icons.email_outlined
                                : Icons.phone_iphone_outlined,
                            size: 20,
                          ),
                          label: Text(
                            _usePhoneLogin
                                ? context.t.features.auth.emailLogin
                                : context.t.features.auth.phoneLogin,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.cardRadius,
                              ),
                            ),
                            textStyle: AppTypography.body1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingXS),
                        Center(
                          child: Semantics(
                            button: true,
                            label: context.t.common.forgotPassword,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: authState.isLoading
                                  ? null
                                  : () => context.push('/forgot-password'),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: AppSizes.minTouchTarget,
                                  minHeight: AppSizes.minTouchTarget,
                                ),
                                child: Center(
                                  child: Text(
                                    context.t.common.forgotPassword,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.body2.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingFieldSpacing),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColors.border,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.spacingM,
                              ),
                              child: Text(
                                context.t.features.auth.or,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColors.border,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.spacingFieldSpacing),
                        AltActionButton(
                          icon: Icons.person_add_outlined,
                          title: context.t.features.auth.noAccount,
                          onTap: authState.isLoading
                              ? null
                              : () => context.push('/register'),
                          isEnabled: !authState.isLoading,
                        ),
                        const SizedBox(height: AppSizes.spacingFieldSpacing),
                        AltActionButton(
                          icon: Icons.vpn_key_outlined,
                          title: context.t.features.auth.joinWithCode,
                          onTap: authState.isLoading
                              ? null
                              : () => context.push('/join'),
                          isEnabled: !authState.isLoading,
                        ),
                        const SizedBox(height: AppSizes.spacingL),
                        Text(
                          '${context.t.features.auth.copyright} v${AppConstants.appVersion}',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
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
