import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Logo / Brand (source of truth) ──
  static const Color brandOrange = Color(0xFFF15A22);
  static const Color brandOrangeLight = Color(0xFFFF7A4D);
  static const Color brandOrangeDark = Color(0xFFD44A15);
  static const Color brandOrangeSoft = Color(0xFFFFF3ED);

  static const Color brandBlue = Color(0xFF4285F4);
  static const Color brandBlueLight = Color(0xFF6BA3FF);
  static const Color brandBlueDark = Color(0xFF1565C0);
  static const Color brandBlueSoft = Color(0xFFEEF2FF);

  // ── Neutral Greys (Light) ──
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFF8FAFC);
  static const Color grey100 = Color(0xFFF1F5F9);
  static const Color grey200 = Color(0xFFE2E8F0);
  static const Color grey300 = Color(0xFFCBD5E1);
  static const Color grey400 = Color(0xFF94A3B8);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey600 = Color(0xFF475569);
  static const Color grey700 = Color(0xFF334155);
  static const Color grey800 = Color(0xFF1E293B);
  static const Color grey900 = Color(0xFF0F172A);

  // ── Dark Mode Palette (premium, not inversion) ──
  static const Color darkBg = Color(0xFF0E1117);
  static const Color darkCard = Color(0xFF1A1D24);
  static const Color darkSurface = Color(0xFF232833);
  static const Color darkBorder = Color(0xFF313846);
  static const Color darkBorderLight = Color(0xFF2A2F3A);
  static const Color darkPrimary = Color(0xFFFF6A2A);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB7BDC8);
  static const Color darkTextTertiary = Color(0xFF6B7280);

  // ── Semantic ──
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF065F46);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFF7F1D1D);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF78350F);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1E3A5F);

  // ── Semantic Text ──
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnError = Color(0xFFFFFFFF);

  // ── Surfaces ──
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF0E1117);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1A1D24);

  // ── Borders ──
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF313846);

  // ── Glass (for glassmorphism effects) ──
  static const Color glassWhite = Color(0x0DFFFFFF);
  static const Color glassWhiteMed = Color(0x1AFFFFFF);
  static const Color glassWhiteStrong = Color(0x33FFFFFF);
  static const Color glassDark = Color(0x0D000000);
  static const Color glassDarkMed = Color(0x1A000000);

  // ── Gradient Stops ──
  static const Color gradientStart = Color(0xFFF15A22);
  static const Color gradientMid = Color(0xFFE8451A);
  static const Color gradientEnd = Color(0xFFD44A15);

  // ── Legacy (kept for backward compatibility during migration) ──
  static const Color primaryBlue = brandBlue;
  static const Color accentOrange = brandOrange;
  static const Color backgroundWhite = white;
  static const Color backgroundLightGrey = grey100;
  static const Color backgroundInputFill = grey50;
  static const Color borderGrey = borderLight;
  static const Color iconDefault = grey600;
  static const Color iconActive = brandBlue;
  static const Color successGreen = success;
  static const Color errorRed = error;
}
