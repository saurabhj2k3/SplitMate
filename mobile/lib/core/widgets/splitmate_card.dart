import 'package:flutter/material.dart';
import '../constants/colors.dart';

class SplitMateCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double borderRadius;
  final bool hasShadow;
  final bool hasStickyTape;
  final String? tapeText;
  final double borderWidth;

  const SplitMateCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.backgroundColor,
    this.borderRadius = 14,
    this.hasShadow = true,
    this.hasStickyTape = false,
    this.tapeText,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border, width: borderWidth),
        boxShadow: hasShadow
            ? [
                const BoxShadow(
                  color: AppColors.shadowColor,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (hasStickyTape) {
      cardContent = Stack(
        clipBehavior: Clip.none,
        children: [
          cardContent,
          Positioned(
            top: -8,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.yellowTape,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: tapeText != null
                  ? Text(
                      tapeText!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    )
                  : const SizedBox(width: 24, height: 4),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
