import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_typography.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/profile/presentation/widgets/change_password_bottom_sheet.dart';
import '../../features/profile/presentation/widgets/delete_account_dialog.dart';
import '../../l10n/strings.g.dart';
import 'toast_overlay.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final currentLocale = ref.watch(localeProvider);

    return SingleChildScrollView(
      padding: AppSizes.screenBodyScrollPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (user != null) _ProfileCard(user: user),
          const SizedBox(height: AppSizes.spacingL),

          _SectionHeader(title: context.t.common.account),
          const SizedBox(height: AppSizes.spacingS),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.lock_outline,
                title: context.t.common.changePassword,
                onTap: () => ChangePasswordBottomSheet.show(context),
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.language,
                title: context.t.common.language,
                trailing: currentLocale == AppLocale.tr ? 'Türkçe' : 'English',
                onTap: () => _showLanguageSheet(context, ref),
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: context.t.common.notifications,
                onTap: () => _showComingSoon(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingL),

          _SectionHeader(title: context.t.common.info),
          const SizedBox(height: AppSizes.spacingS),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: context.t.common.privacyPolicy,
                onTap: () => _showComingSoon(context, ref),
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.shield_outlined,
                title: context.t.common.kvkk,
                onTap: () => _showComingSoon(context, ref),
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.help_outline,
                title: context.t.common.helpSupport,
                onTap: () => _showComingSoon(context, ref),
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.info_outline,
                title: context.t.common.about,
                trailing: 'v${AppConstants.appVersion}',
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingL),

          _SectionHeader(title: context.t.common.dangerZone),
          const SizedBox(height: AppSizes.spacingS),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.delete_forever_outlined,
                title: context.t.common.deleteAccount,
                iconColor: AppColors.error,
                titleColor: AppColors.error,
                onTap: () => DeleteAccountDialog.show(context),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingXL),

          if (kDebugMode) ...[
            _TokenTestButton(),
            const SizedBox(height: AppSizes.spacingM),
          ],

          _LogoutButton(),
          const SizedBox(height: AppSizes.spacingL),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, WidgetRef ref) {
    ref
        .read(toastProvider.notifier)
        .show(context.t.common.comingSoon, type: ToastType.info);
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BottomSheetHandle(),
            const SizedBox(height: AppSizes.spacingM),
            Text(context.t.common.language, style: AppTypography.h3),
            const SizedBox(height: AppSizes.spacingL),
            _LanguageOption(
              flag: '🇹🇷',
              title: 'Türkçe',
              subtitle: 'Turkish',
              isSelected: currentLocale == AppLocale.tr,
              onTap: () {
                changeLocale(ref, AppLocale.tr);
                Navigator.pop(sheetContext);
              },
            ),
            const SizedBox(height: AppSizes.spacingS),
            _LanguageOption(
              flag: '🇬🇧',
              title: 'English',
              subtitle: 'İngilizce',
              isSelected: currentLocale == AppLocale.en,
              onTap: () {
                changeLocale(ref, AppLocale.en);
                Navigator.pop(sheetContext);
              },
            ),
            const SizedBox(height: AppSizes.spacingM),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: 'v${AppConstants.appVersion}',
      applicationLegalese: context.t.common.copyright,
      children: [
        const SizedBox(height: AppSizes.spacingM),
        Text(
          context.t.common.aboutDescription,
          style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserEntity user;

  const _ProfileCard({required this.user});

  String get _initials {
    final parts = user.name
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = user.role == UserRole.manager
        ? context.t.common.manager
        : context.t.common.resident;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingM,
        vertical: AppSizes.spacingL,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Text(
              _initials,
              style: AppTypography.h2.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTypography.h3.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.spacingXS),
                if (user.email.isNotEmpty) ...[
                  Text(
                    user.email,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else if (user.phone != null && user.phone!.isNotEmpty) ...[
                  Text(
                    user.phone!,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSizes.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleLabel,
                    style: AppTypography.label.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingM,
          vertical: AppSizes.spacingM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: AppSizes.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body1.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingS),
      child: Text(
        title,
        style: AppTypography.label.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingM,
          vertical: AppSizes.spacingM,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: AppSizes.iconSize, color: iconColor ?? AppColors.primary),
            const SizedBox(width: AppSizes.spacingM),
            Expanded(
              child: Text(
                title,
                style: AppTypography.body1.copyWith(
                  color: titleColor ?? AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSizes.spacingS),
            ],
            const Icon(
              Icons.chevron_right,
              size: AppSizes.iconSize,
              color: AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return ElevatedButton.icon(
      onPressed: authState.isLoading
          ? null
          : () => _confirmLogout(context, ref),
      icon: const Icon(Icons.logout_rounded, size: AppSizes.iconSize),
      label: Text(context.t.common.logout),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, AppSizes.buttonHeightPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
        ),
        textStyle: AppTypography.button,
        elevation: 0,
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BottomSheetHandle(),
            const SizedBox(height: AppSizes.spacingL),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.spacingM),
            Text(
              context.t.common.logout,
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSizes.spacingS),
            Text(
              context.t.common.logoutConfirm,
              style: AppTypography.body1.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingXL),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: AppSizes.buttonHeightSecondary,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
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
                        context.t.common.cancelBtn,
                        style: AppTypography.button.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.spacingM),
                Expanded(
                  child: SizedBox(
                    height: AppSizes.buttonHeightSecondary,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.buttonRadius,
                          ),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await ref.read(authStateProvider.notifier).logout(ref);
                        if (!context.mounted) return;
                        ref.read(toastProvider.notifier).show(
                              context.t.common.logoutSuccess,
                              type: ToastType.success,
                              duration: const Duration(seconds: 4),
                            );
                        context.go('/');
                      },
                      child: Text(
                        context.t.common.logout,
                        style: AppTypography.button,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TokenTestButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _checkTokenExpiry(context, ref),
      icon: const Icon(Icons.timer_outlined, size: AppSizes.iconSize),
      label: Text(context.t.common.tokenExpiryTest),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, AppSizes.buttonHeightPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
        ),
        textStyle: AppTypography.button,
        elevation: 0,
      ),
    );
  }

  Future<void> _checkTokenExpiry(BuildContext context, WidgetRef ref) async {
    final secureStorage = ref.read(secureStorageProvider);
    final isExpired = await secureStorage.isTokenExpired();
    final expiry = await secureStorage.getTokenExpiry();

    if (!context.mounted) return;

    if (isExpired) {
      ref
          .read(toastProvider.notifier)
          .show(context.t.common.tokenExpired, type: ToastType.error);
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        context.go('/login');
      }
    } else {
      final remaining = expiry?.difference(DateTime.now()) ?? Duration.zero;
      ref
          .read(toastProvider.notifier)
          .show(
            '${context.t.common.tokenActive} ${remaining.inSeconds} saniye',
            type: ToastType.success,
          );
    }
  }
}
