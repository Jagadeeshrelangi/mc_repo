import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const String _fontBody = 'Inter';
  static const String _fontDisplay = 'Space Grotesk';

  // ── Hero (very large, Space Grotesk) ──
  static const TextStyle heroLg = TextStyle(
    fontFamily: _fontDisplay, fontSize: 40, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -1.0,
  );
  static const TextStyle heroMd = TextStyle(
    fontFamily: _fontDisplay, fontSize: 36, fontWeight: FontWeight.w700, height: 1.18, letterSpacing: -0.8,
  );
  static const TextStyle heroSm = TextStyle(
    fontFamily: _fontDisplay, fontSize: 32, fontWeight: FontWeight.w700, height: 1.22, letterSpacing: -0.5,
  );

  // ── Display (Space Grotesk) ──
  static const TextStyle displayLg = TextStyle(
    fontFamily: _fontDisplay, fontSize: 28, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.3,
  );
  static const TextStyle displayMd = TextStyle(
    fontFamily: _fontDisplay, fontSize: 24, fontWeight: FontWeight.w700, height: 1.28, letterSpacing: -0.2,
  );
  static const TextStyle displaySm = TextStyle(
    fontFamily: _fontDisplay, fontSize: 20, fontWeight: FontWeight.w600, height: 1.33,
  );

  // ── Headline (Space Grotesk) ──
  static const TextStyle headlineLg = TextStyle(
    fontFamily: _fontDisplay, fontSize: 18, fontWeight: FontWeight.w700, height: 1.4,
  );
  static const TextStyle headlineMd = TextStyle(
    fontFamily: _fontDisplay, fontSize: 16, fontWeight: FontWeight.w600, height: 1.44,
  );
  static const TextStyle headlineSm = TextStyle(
    fontFamily: _fontDisplay, fontSize: 15, fontWeight: FontWeight.w600, height: 1.5,
  );

  // ── Title (Inter, semibold) ──
  static const TextStyle titleLg = TextStyle(
    fontFamily: _fontBody, fontSize: 16, fontWeight: FontWeight.w600, height: 1.5,
  );
  static const TextStyle titleMd = TextStyle(
    fontFamily: _fontBody, fontSize: 14, fontWeight: FontWeight.w600, height: 1.43,
  );
  static const TextStyle titleSm = TextStyle(
    fontFamily: _fontBody, fontSize: 13, fontWeight: FontWeight.w600, height: 1.38,
  );

  // ── Body (Inter, regular) ──
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _fontBody, fontSize: 15, fontWeight: FontWeight.w400, height: 1.6,
  );
  static const TextStyle bodyMd = TextStyle(
    fontFamily: _fontBody, fontSize: 14, fontWeight: FontWeight.w400, height: 1.57,
  );
  static const TextStyle bodySm = TextStyle(
    fontFamily: _fontBody, fontSize: 13, fontWeight: FontWeight.w400, height: 1.54,
  );

  // ── Label (Inter, medium/semibold) ──
  static const TextStyle labelLg = TextStyle(
    fontFamily: _fontBody, fontSize: 14, fontWeight: FontWeight.w600, height: 1.43,
  );
  static const TextStyle labelMd = TextStyle(
    fontFamily: _fontBody, fontSize: 12, fontWeight: FontWeight.w600, height: 1.33,
  );
  static const TextStyle labelSm = TextStyle(
    fontFamily: _fontBody, fontSize: 11, fontWeight: FontWeight.w500, height: 1.45,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: _fontBody, fontSize: 10, fontWeight: FontWeight.w500, height: 1.4,
  );

  // ── Overline ──
  static const TextStyle overline = TextStyle(
    fontFamily: _fontBody, fontSize: 10, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 1.2,
  );
}
