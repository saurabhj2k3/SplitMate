import 'package:flutter/material.dart';

/// Design tokens conforming to the playful, ultra-clear notebook & high-contrast fintech aesthetic.
class AppColors {
  // Primary brand & accent colors
  static const Color primary = Color(0xFF7C5CFC); // Vibrant Purple Accent
  static const Color primaryDark = Color(0xFF6342E8);
  static const Color primaryLight = Color(0xFFF3E8FF); // Soft Purple Tint
  
  // High contrast Neubrutalist accents
  static const Color yellowBanner = Color(0xFFFEF08A); // Notebook Sticky Yellow
  static const Color yellowBorder = Color(0xFFFACC15);
  static const Color yellowTape = Color(0xFFFDE047);
  
  // Backgrounds & Notebook canvas
  static const Color background = Color(0xFFFAF9F5); // Warm Notebook Canvas
  static const Color gridLine = Color(0xFFE8E5DD); // Notebook Graph Grid Lines
  static const Color surface = Color(0xFFFFFFFF); // Clean White Card Surface
  static const Color surfaceMuted = Color(0xFFF4F3EE); // Muted surface / table row

  // Bold Outlines & Shadows
  static const Color border = Color(0xFF1E2022); // Solid crisp dark border
  static const Color borderLight = Color(0xFFE2DFD7);
  static const Color shadowColor = Color(0xFF1E2022); // Solid offset shadow

  // Typography Colors
  static const Color textPrimary = Color(0xFF181A1B); // Bold Charcoal Black
  static const Color textSecondary = Color(0xFF6B7280); // Secondary metadata
  static const Color textMuted = Color(0xFF9CA3AF);

  // Financial Status Colors
  static const Color positive = Color(0xFF16A34A); // Crisp Green
  static const Color positiveLight = Color(0xFFDCFCE7);
  static const Color positiveText = Color(0xFF15803D);

  static const Color negative = Color(0xFFDC2626); // Crisp Red
  static const Color negativeLight = Color(0xFFFEE2E2);
  static const Color negativeText = Color(0xFFB91C1C);

  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningText = Color(0xFFB45309);
  
  // Teal accent for date badges
  static const Color dateBadgeBg = Color(0xFFCCFBF1);
  static const Color dateBadgeText = Color(0xFF0F766E);
}
