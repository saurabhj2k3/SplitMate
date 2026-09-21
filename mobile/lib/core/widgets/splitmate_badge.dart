import 'package:flutter/material.dart';
import '../constants/colors.dart';

enum BadgeVariant { neutral, success, error, warning, primary }

class SplitMateBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;

  const SplitMateBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (variant) {
      case BadgeVariant.neutral:
        bg = AppColors.surfaceMuted;
        fg = AppColors.textSecondary;
        break;
      case BadgeVariant.success:
        bg = AppColors.positiveLight;
        fg = AppColors.positiveText;
        break;
      case BadgeVariant.error:
        bg = AppColors.negativeLight;
        fg = AppColors.negativeText;
        break;
      case BadgeVariant.warning:
        bg = AppColors.warningLight;
        fg = AppColors.warningText;
        break;
      case BadgeVariant.primary:
        bg = AppColors.primaryLight;
        fg = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
