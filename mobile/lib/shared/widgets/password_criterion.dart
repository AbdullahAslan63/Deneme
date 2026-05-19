import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PasswordCriterion extends StatelessWidget {
  final String text;
  final bool isMet;

  const PasswordCriterion({
    super.key,
    required this.text,
    required this.isMet,
  });

  static const _metIcon = Icon(Icons.check_circle, color: AppColors.success, size: 16);
  static const _unmetIcon = Icon(Icons.cancel, color: AppColors.error, size: 16);
  static const _metStyle = TextStyle(color: AppColors.success, fontSize: 12);
  static const _unmetStyle = TextStyle(color: AppColors.error, fontSize: 12);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          isMet ? _metIcon : _unmetIcon,
          const SizedBox(width: 8),
          Text(text, style: isMet ? _metStyle : _unmetStyle),
        ],
      ),
    );
  }
}
