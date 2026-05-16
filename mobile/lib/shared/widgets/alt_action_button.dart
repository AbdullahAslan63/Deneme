import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_typography.dart';

/// Alternatif aksiyon butonu - card-style, ikon + başlık + ok
/// Kaydol/Katıl gibi ikincil aksiyonlar için kullanılır
class AltActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool isEnabled;

  const AltActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Container(
          height: AppSizes.buttonHeightSecondary,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(
              color: isEnabled
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isEnabled
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.5),
                size: 24,
              ),
              const SizedBox(width: AppSizes.spacingM),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body1.copyWith(
                    color: isEnabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isEnabled
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
