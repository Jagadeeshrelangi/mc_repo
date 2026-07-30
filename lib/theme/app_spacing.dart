import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppSpacing {
  AppSpacing._();

  // ── Spacing Scale (4px base) ──
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double xxxxl = 48;
  static const double hero = 64;

  // ── Common EdgeInsets ──
  static const EdgeInsets pageH = EdgeInsets.symmetric(horizontal: base);
  static const EdgeInsets pageAll = EdgeInsets.all(base);
  static const EdgeInsets cardH = EdgeInsets.symmetric(horizontal: base, vertical: md);
  static const EdgeInsets cardAll = EdgeInsets.all(base);
  static const EdgeInsets buttonH = EdgeInsets.symmetric(horizontal: xl, vertical: 0);

  // ── Corner Radius (softer, more premium) ──
  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 22;
  static const double radiusXxl = 28;
  static const double radiusFull = 999;

  // ── Common BorderRadius ──
  static final BorderRadius brXs = BorderRadius.circular(radiusXs);
  static final BorderRadius brSm = BorderRadius.circular(radiusSm);
  static final BorderRadius brMd = BorderRadius.circular(radiusMd);
  static final BorderRadius brLg = BorderRadius.circular(radiusLg);
  static final BorderRadius brXl = BorderRadius.circular(radiusXl);
  static final BorderRadius brXxl = BorderRadius.circular(radiusXxl);
  static final BorderRadius brFull = BorderRadius.circular(radiusFull);
}

class AppElevation {
  AppElevation._();

  static const double none = 0;
  static const double low = 1;
  static const double medium = 2;
  static const double high = 3;
  static const double higher = 4;
  static const double highest = 5;

  // ── Light Mode Shadows (soft, premium) ──
  static final List<BoxShadow> shadowLow = [
    const BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static final List<BoxShadow> shadowMedium = [
    const BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];
  static final List<BoxShadow> shadowHigh = [
    const BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 6)),
  ];
  static final List<BoxShadow> shadowHigher = [
    const BoxShadow(color: Color(0x16000000), blurRadius: 32, offset: Offset(0, 10)),
  ];
  static final List<BoxShadow> shadowHighest = [
    const BoxShadow(color: Color(0x1A000000), blurRadius: 48, offset: Offset(0, 16)),
  ];

  // ── Brand Shadows (orange glow) ──
  static final List<BoxShadow> shadowBrand = [
    BoxShadow(color: AppColors.brandOrange.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 6)),
  ];
  static final List<BoxShadow> shadowBrandLight = [
    BoxShadow(color: AppColors.brandOrange.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 3)),
  ];

  // ── Dark Mode Shadows ──
  static final List<BoxShadow> shadowDarkLow = [
    const BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static final List<BoxShadow> shadowDarkMedium = [
    const BoxShadow(color: Color(0x24000000), blurRadius: 12, offset: Offset(0, 3)),
  ];
  static final List<BoxShadow> shadowDarkHigh = [
    const BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 6)),
  ];
}
