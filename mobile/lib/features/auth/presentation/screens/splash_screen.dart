import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/platform/system_navigator_bridge.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/providers/navigation_provider.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../domain/entities/user_entity.dart' show UserRole;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Branding için minimum görünme süresi.
  // Oturum kurtarma daha hızlı bitse bile splash bu süreden önce kaybolmaz.
  static const Duration _minSplashDuration = Duration(milliseconds: 800);

  // Refresh token endpoint'i veya keychain çağrısı çok uzun sürerse (uçak
  // modu, sunucu down, yavaş ağ) bu süre sonunda kullanıcıya "Tekrar dene"
  // butonu gösterilir. Dio default timeout'larından biraz daha uzun.
  static const Duration _bootstrapTimeout = Duration(seconds: 12);

  // Bootstrap başarısız olduğunda gösterilecek hata bayrağı; null ise
  // normal splash görünür, doluysa retry UI'ı çıkar.
  bool _hasBootError = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    // Splash yalnızca yeni process (cold start) veya çıkış sonrası go('/') ile
    // girilir. Sekme / alt navigasyon sadece process yaşarken bellekte tutulur;
    // arka plandan tamamen kapatılınca veya RAM öldürünce temiz başlangıç.
    _resetNavigationForFreshEntry();
    if (mounted) {
      setState(() => _hasBootError = false);
    }

    final restoreFuture =
        ref.read(authStateProvider.notifier).restoreSession();
    final minDelayFuture = Future<void>.delayed(_minSplashDuration);

    // restoreSession bitince yönlendir; pre-warm'ı dashboard mount olduktan
    // sonra ConsumerStatefulWidget'in initState'i kendisi tetikler. Splash
    // sırasında pre-warm denemesi UI thread'i bloklayıp ANR'a yol açıyordu.
    try {
      await Future.wait<void>([restoreFuture, minDelayFuture])
          .timeout(_bootstrapTimeout);
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _hasBootError = true);
      return;
    } catch (_) {
      // restoreSession kendi içinde hata yutuyor; buraya beklenmedik bir
      // şey düşerse de retry UI göster.
      if (!mounted) return;
      setState(() => _hasBootError = true);
      return;
    }

    if (!mounted) return;
    _navigateBasedOnAuth();
  }

  void _resetNavigationForFreshEntry() {
    ref.read(managerTabIndexProvider.notifier).state = 0;
    ref.read(residentTabIndexProvider.notifier).state = 0;
  }

  /// Bootstrap timeout veya beklenmedik bir hata olduğunda gösterilen
  /// alt bölüm. Kullanıcı yine splash'ta kalır; tekrar deneyene kadar
  /// uygulamanın derinine yönlendirilmez.
  Widget _buildRetrySection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.dashboardScreenPaddingHorizontal,
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: Colors.white.withValues(alpha: 0.85),
            size: 32,
          ),
          const SizedBox(height: AppSizes.spacingM),
          Text(
            context.t.features.auth.splashConnectionError,
            textAlign: TextAlign.center,
            style: AppTypography.body1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            context.t.features.auth.splashConnectionHint,
            textAlign: TextAlign.center,
            style: AppTypography.body2
                .copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: AppSizes.spacingL),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _bootstrap,
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              label: Text(
                context.t.features.buildings.tekrarDene,
                style: AppTypography.body1.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingS),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                if (!mounted) return;
                context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                ),
              ),
              child: Text(
                context.t.features.auth.skipToLogin,
                style: AppTypography.body2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateBasedOnAuth() {
    final authState = ref.read(authStateProvider);
    if (authState.isAuthenticated && authState.user != null) {
      if (authState.user!.role == UserRole.manager) {
        context.go('/manager-dashboard');
      } else {
        context.go('/resident-dashboard');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await SystemNavigatorBridge.moveAppToBackground();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.apartment,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    context.t.features.auth.appTitle,
                    style: AppTypography.h1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.t.features.auth.appSubtitle,
                    style: AppTypography.body1.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  if (_hasBootError)
                    _buildRetrySection(context)
                  else
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white70),
                      ),
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
