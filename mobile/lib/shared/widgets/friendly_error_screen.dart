import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_typography.dart';

/// Yakalanmamış bir build-time hatasında Flutter'ın varsayılan kıpkırmızı
/// `ErrorWidget`'ı yerine basılır. Hem debug hem release modda çalışır.
///
/// - **Release** modda kullanıcıya teknik mesaj gösterilmez (CLAUDE.md kuralı).
/// - **Debug** modda geliştiricinin görmesi için exception'ın `toString()`'i
///   küçük puntoyla altta gösterilir (kullanıcı için olmadığı etiketi var).
class FriendlyErrorScreen extends StatelessWidget {
  final FlutterErrorDetails details;

  const FriendlyErrorScreen({super.key, required this.details});

  _ErrorCopy _copy() {
    final ex = details.exception;
    if (ex is NetworkException) {
      return const _ErrorCopy(
        icon: Icons.wifi_off_rounded,
        title: 'İnternet bağlantısı yok',
        message:
            'Telefonunuzun internete bağlı olduğundan emin olup tekrar deneyin.',
      );
    }
    if (ex is UnauthorizedException) {
      return const _ErrorCopy(
        icon: Icons.lock_outline_rounded,
        title: 'Oturum sona erdi',
        message: 'Lütfen uygulamayı kapatıp tekrar giriş yapın.',
      );
    }
    if (ex is ServerException) {
      return const _ErrorCopy(
        icon: Icons.cloud_off_rounded,
        title: 'Sunucuya ulaşılamıyor',
        message: 'Biraz sonra tekrar deneyebilir misiniz?',
      );
    }
    return const _ErrorCopy(
      icon: Icons.error_outline,
      title: 'Bu sayfa açılamadı',
      message: 'Lütfen uygulamayı kapatıp tekrar açın.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copy();
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: AppSizes.screenBodyScrollPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  copy.icon,
                  color: AppColors.error,
                  size: 44,
                ),
              ),
              const SizedBox(height: AppSizes.spacingL),
              Text(
                copy.title,
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacingS),
              Text(
                copy.message,
                style: AppTypography.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: AppSizes.spacingL),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sadece geliştirici görür (debug):',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        details.exceptionAsString(),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCopy {
  final IconData icon;
  final String title;
  final String message;

  const _ErrorCopy({
    required this.icon,
    required this.title,
    required this.message,
  });
}
