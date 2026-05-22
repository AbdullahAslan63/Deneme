import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Küçük sayı rozeti (bildirim zili, hızlı aksiyon kartları).
class CountBadge extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;
  final double? size;

  const CountBadge({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final display = count > 99 ? '99+' : count.toString();
    final side = size ?? 20.0;

    return Container(
      constraints: BoxConstraints(minWidth: side, minHeight: side),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.error,
        borderRadius: BorderRadius.circular(side / 2),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? AppColors.error).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        display,
        style: AppTypography.caption.copyWith(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          height: 1.1,
        ),
      ),
    );
  }
}
