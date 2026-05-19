import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/auth_validators.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/alt_action_button.dart';
import '../../../../shared/widgets/password_field.dart';
import '../../../../shared/widgets/password_criterion.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../providers/auth_provider.dart';

class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  static final _upperRegex = RegExp(r'[A-Z]');
  static final _lowerRegex = RegExp(r'[a-z]');
  static final _digitRegex = RegExp(r'\d');
  static final _specialRegex = RegExp(r'[@$!%*?&.]');
  late TextEditingController _inviteCodeController;
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  // Klavye "next" zinciri için her alanın FocusNode'u.
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _inviteCodeError;
  String? _phoneError;
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _passwordsMatch = false;
  DateTime? _lastBackPressAt;

  @override
  void initState() {
    super.initState();
    _inviteCodeController = TextEditingController();
    _emailController = TextEditingController();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _handleJoin(BuildContext context) {
    // Backend join ucu `inviteCode` için trim + uppercase + iç boşluk silme
    // uyguluyor; client de aynı normalizasyonu yapsın ki kullanıcı küçük harf
    // veya "ap3- b12 -a9f0" girse bile gönderim ve doğrulama doğru çalışsın.
    final inviteCode = AuthValidators.normalizeInviteCode(
      _inviteCodeController.text,
    );
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (inviteCode.isEmpty ||
        email.isEmpty ||
        name.isEmpty ||
        password.isEmpty) {
      ref
          .read(toastProvider.notifier)
          .show(
            context.t.features.auth.inviteCodeAndPasswordRequired,
            type: ToastType.error,
          );
      return;
    }

    if (!AuthValidators.isValidInviteCode(inviteCode)) {
      ref
          .read(toastProvider.notifier)
          .show(
            context.t.features.auth.invalidInviteCodeFormat,
            type: ToastType.error,
          );
      return;
    }

    final emailError = InputValidators.validateEmail(email);
    if (emailError != null) {
      final errorMessage = emailError == 'email_required'
          ? context.t.validation.emailRequired
          : emailError == 'email_invalid'
          ? context.t.validation.emailInvalid
          : context.t.validation.emailTooLong;
      ref
          .read(toastProvider.notifier)
          .show(errorMessage, type: ToastType.error);
      return;
    }

    if (phone.isNotEmpty && !AuthValidators.isValidPhone(phone)) {
      ref
          .read(toastProvider.notifier)
          .show(
            context.t.features.auth.invalidPhoneFormat,
            type: ToastType.error,
          );
      return;
    }

    if (password != confirmPassword) {
      ref
          .read(toastProvider.notifier)
          .show(
            context.t.features.auth.passwordsDoNotMatch,
            type: ToastType.error,
          );
      return;
    }

    final passwordError = InputValidators.validatePassword(password);
    if (passwordError != null) {
      final errorMessage = passwordError == 'password_required'
          ? context.t.validation.passwordRequired
          : passwordError == 'password_too_short'
          ? context.t.validation.passwordTooShort
          : passwordError == 'password_too_long'
          ? context.t.validation.passwordTooLong
          : passwordError == 'password_uppercase_required'
          ? context.t.validation.passwordUppercaseRequired
          : passwordError == 'password_lowercase_required'
          ? context.t.validation.passwordLowercaseRequired
          : passwordError == 'password_number_required'
          ? context.t.validation.passwordNumberRequired
          : context.t.validation.passwordSpecialCharRequired;
      ref
          .read(toastProvider.notifier)
          .show(errorMessage, type: ToastType.error);
      return;
    }

    ref
        .read(authStateProvider.notifier)
        .join(
          inviteCode,
          email,
          password,
          name,
          phone.isEmpty ? null : phone,
          ref,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (previous, next) {
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
        if (authState.isLoading) return;
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
          return;
        }
        final now = DateTime.now();
        final shouldExit = _lastBackPressAt != null &&
            now.difference(_lastBackPressAt!) < const Duration(seconds: 2);
        if (shouldExit) {
          await SystemNavigator.pop();
          return;
        }
        _lastBackPressAt = now;
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(context.t.common.pressBackAgainToExit)),
          );
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 140,
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
                            context.t.features.auth.joinApartment,
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
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _inviteCodeController,
                                enabled: !authState.isLoading,
                                textCapitalization:
                                    TextCapitalization.characters,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) =>
                                    _emailFocusNode.requestFocus(),
                                style: AppTypography.body1,
                                decoration: InputDecoration(
                                  labelText: context.t.features.auth.inviteCode,
                                  hintText:
                                      context.t.features.auth.inviteCodeHint,
                                  prefixIcon: Icon(
                                    Icons.vpn_key_outlined,
                                    size: AppSizes.iconSize,
                                  ),
                                  errorText: _inviteCodeError,
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
                                onChanged: (value) {
                                  final normalized = AuthValidators
                                      .normalizeInviteCode(value);
                                  setState(() {
                                    if (normalized.isNotEmpty &&
                                        !AuthValidators.isValidInviteCode(
                                          normalized,
                                        )) {
                                      _inviteCodeError = context
                                          .t
                                          .features
                                          .auth
                                          .invalidInviteCodeFormat;
                                    } else {
                                      _inviteCodeError = null;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(
                                height: AppSizes.spacingFieldSpacing,
                              ),
                              TextField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                enabled: !authState.isLoading,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) =>
                                    _nameFocusNode.requestFocus(),
                                autofillHints: const [
                                  AutofillHints.newUsername,
                                  AutofillHints.email,
                                ],
                                style: AppTypography.body1,
                                decoration: InputDecoration(
                                  labelText: context.t.features.auth.email,
                                  hintText: context.t.features.auth.emailHint,
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    size: AppSizes.iconSize,
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
                              const SizedBox(
                                height: AppSizes.spacingFieldSpacing,
                              ),
                              TextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                enabled: !authState.isLoading,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) =>
                                    _phoneFocusNode.requestFocus(),
                                autofillHints: const [AutofillHints.name],
                                textCapitalization: TextCapitalization.words,
                                style: AppTypography.body1,
                                decoration: InputDecoration(
                                  labelText: context.t.features.auth.name,
                                  hintText: context.t.features.auth.nameHint,
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    size: AppSizes.iconSize,
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
                              const SizedBox(
                                height: AppSizes.spacingFieldSpacing,
                              ),
                              TextField(
                                controller: _phoneController,
                                focusNode: _phoneFocusNode,
                                enabled: !authState.isLoading,
                                keyboardType: TextInputType.number,
                                maxLength: 10,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) =>
                                    _passwordFocusNode.requestFocus(),
                                autofillHints: const [
                                  AutofillHints.telephoneNumberNational,
                                ],
                                style: AppTypography.body1,
                                decoration: InputDecoration(
                                  labelText:
                                      context.t.features.auth.phoneOptional,
                                  hintText:
                                      context.t.features.auth.phoneHintOptional,
                                  prefixText: '+90 ',
                                  prefixIcon: Icon(
                                    Icons.phone_outlined,
                                    size: AppSizes.iconSize,
                                  ),
                                  counterText: '',
                                  errorText: _phoneError,
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
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    if (value.isNotEmpty &&
                                        !AuthValidators.isValidPhone(value)) {
                                      _phoneError = context
                                          .t
                                          .features
                                          .auth
                                          .invalidPhoneNumber;
                                    } else {
                                      _phoneError = null;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(
                                height: AppSizes.spacingFieldSpacing,
                              ),
                              PasswordField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                labelText: context.t.features.auth.password,
                                hintText: context.t.features.auth.passwordHint,
                                onToggleVisibility: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                                enabled: !authState.isLoading,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) =>
                                    _confirmPasswordFocusNode.requestFocus(),
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _hasMinLength = value.length >= 6;
                                    _hasUpperCase = _upperRegex.hasMatch(value);
                                    _hasLowerCase = _lowerRegex.hasMatch(value);
                                    _hasNumber = _digitRegex.hasMatch(value);
                                    _hasSpecialChar = _specialRegex.hasMatch(
                                      value,
                                    );
                                  });
                                },
                                focusNode: _passwordFocusNode,
                                passwordCriteria: _passwordFocusNode.hasFocus
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          PasswordCriterion(
                                            text: context
                                                .t
                                                .features
                                                .auth
                                                .minLength,
                                            isMet: _hasMinLength,
                                          ),
                                          PasswordCriterion(
                                            text: context
                                                .t
                                                .features
                                                .auth
                                                .hasUpperCase,
                                            isMet: _hasUpperCase,
                                          ),
                                          PasswordCriterion(
                                            text: context
                                                .t
                                                .features
                                                .auth
                                                .hasLowerCase,
                                            isMet: _hasLowerCase,
                                          ),
                                          PasswordCriterion(
                                            text: context
                                                .t
                                                .features
                                                .auth
                                                .hasNumber,
                                            isMet: _hasNumber,
                                          ),
                                          PasswordCriterion(
                                            text: context
                                                .t
                                                .features
                                                .auth
                                                .hasSpecialChar,
                                            isMet: _hasSpecialChar,
                                          ),
                                        ],
                                      )
                                    : null,
                              ),
                              const SizedBox(
                                height: AppSizes.spacingFieldSpacing,
                              ),
                              PasswordField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                labelText:
                                    context.t.features.auth.confirmPassword,
                                hintText: context.t.features.auth.passwordHint,
                                onToggleVisibility: () {
                                  setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  );
                                },
                                enabled: !authState.isLoading,
                                focusNode: _confirmPasswordFocusNode,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _handleJoin(context),
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _passwordsMatch =
                                        value == _passwordController.text;
                                  });
                                },
                                helperText:
                                    _confirmPasswordController.text.isEmpty
                                    ? null
                                    : _passwordsMatch
                                    ? null
                                    : context
                                          .t
                                          .features
                                          .auth
                                          .passwordsDoNotMatch,
                              ),
                              const SizedBox(height: AppSizes.spacingL),
                              ElevatedButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () => _handleJoin(context),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(context.t.features.auth.join),
                              ),
                              const SizedBox(
                                height: AppSizes.spacingFieldSpacing,
                              ),
                              AltActionButton(
                                icon: Icons.person_add_outlined,
                                title: context.t.features.auth.areYouManager,
                                onTap: authState.isLoading
                                    ? null
                                    : () => context.push('/register'),
                                isEnabled: !authState.isLoading,
                              ),
                              const SizedBox(height: AppSizes.spacingXL),
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
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: authState.isLoading ? null : () => context.pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
