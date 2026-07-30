import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

// ── BuildContext extension for theme-aware colors ──
extension ThemeHelpers on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ── Surfaces ──
  Color get bgPrimary => isDark ? AppColors.darkBg : AppColors.grey50;
  Color get bgSecondary => isDark ? AppColors.darkCard : AppColors.white;
  Color get bgTertiary => isDark ? AppColors.darkSurface : AppColors.grey50;

  // ── Cards ──
  Color get cardBg => isDark ? AppColors.darkCard : AppColors.white;
  Color get cardBgAlt => isDark ? AppColors.darkSurface : AppColors.grey50;

  // ── Borders ──
  Color get border => isDark ? AppColors.darkBorder : AppColors.borderLight;
  Color get borderSoft => isDark ? AppColors.darkBorderLight : AppColors.grey100;

  // ── Text ──
  Color get textPrimary => isDark ? AppColors.darkText : AppColors.textPrimary;
  Color get textSecondary => isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get textTertiary => isDark ? AppColors.darkTextTertiary : AppColors.textTertiary;
  Color get textOnAccent => AppColors.textOnPrimary;

  // ── Accent ──
  Color get accent => isDark ? AppColors.darkPrimary : AppColors.brandOrange;

  // ── Dividers ──
  Color get divider => isDark ? AppColors.darkBorder : AppColors.grey100;

  // ── Shadows ──
  List<BoxShadow> get shadowLow =>
      isDark ? AppElevation.shadowDarkLow : AppElevation.shadowLow;
  List<BoxShadow> get shadowMedium =>
      isDark ? AppElevation.shadowDarkMedium : AppElevation.shadowMedium;
  List<BoxShadow> get shadowHigh =>
      isDark ? AppElevation.shadowDarkHigh : AppElevation.shadowHigh;
}
