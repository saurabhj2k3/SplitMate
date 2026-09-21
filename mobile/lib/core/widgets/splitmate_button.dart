import 'package:flutter/material.dart';
import '../constants/colors.dart';

enum ButtonVariant { primary, secondary, outline, danger, yellow }

class SplitMateButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;

  const SplitMateButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 42,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color borderColor = AppColors.border;

    switch (variant) {
      case ButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        break;
      case ButtonVariant.secondary:
        bg = AppColors.primaryLight;
        fg = AppColors.primaryDark;
        break;
      case ButtonVariant.outline:
        bg = Colors.white;
        fg = AppColors.textPrimary;
        break;
      case ButtonVariant.danger:
        bg = const Color(0xFFEF4444); // Red
        fg = Colors.white;
        break;
      case ButtonVariant.yellow:
        bg = AppColors.yellowBanner;
        fg = AppColors.textPrimary;
        break;
    }

    final isInteractive = !isLoading && onPressed != null;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isInteractive ? bg : bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: isInteractive
            ? const [
                BoxShadow(
                  color: AppColors.shadowColor,
                  offset: Offset(2.5, 2.5),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isInteractive ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 14, color: fg),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: fg,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
