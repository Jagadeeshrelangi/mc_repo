import 'package:flutter/material.dart';

class AppResponsive {
  AppResponsive._();

  // ── Breakpoints ──
  static const double mobile = 600;
  static const double tablet = 1024;

  // ── Device Type Detection ──
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tablet) return DeviceType.desktop;
    if (width >= mobile) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobile && width < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  // ── Screen Dimensions ──
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  // ── Scaling (clamped) ──
  static double scale(BuildContext context, double base) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scaleFactor = (screenWidth / 390).clamp(0.85, 1.3);
    return (base * scaleFactor).roundToDouble();
  }

  static double scaleFont(BuildContext context, double base) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scaleFactor = (screenWidth / 390).clamp(0.88, 1.2);
    return (base * scaleFactor).roundToDouble();
  }

  static double scaleIcon(BuildContext context, double base) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scaleFactor = (screenWidth / 390).clamp(0.9, 1.15);
    return (base * scaleFactor).roundToDouble();
  }

  static double scaleWidth(BuildContext context, double percent) {
    return MediaQuery.sizeOf(context).width * percent;
  }

  static double scaleHeight(BuildContext context, double percent) {
    return MediaQuery.sizeOf(context).height * percent;
  }

  // ── Content Max Width (for large screens) ──
  static double contentMaxWidth(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    if (screenW >= tablet) return 480;
    if (screenW >= mobile) return 480;
    return screenW;
  }

  // ── Responsive Value ──
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  // ── Grid Columns ──
  static int gridColumns(BuildContext context) {
    return responsive(context, mobile: 2, tablet: 3, desktop: 4);
  }

  // ── Horizontal Padding ──
  static double horizontalPadding(BuildContext context) {
    return responsive(context, mobile: 16, tablet: 24, desktop: 32);
  }
}

enum DeviceType { mobile, tablet, desktop }

// ── Constrained Content Wrapper (centers + max-width on large screens) ──
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final bool centerOnDesktop;

  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.centerOnDesktop = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? AppResponsive.contentMaxWidth(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (screenWidth <= effectiveMaxWidth) return child;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: child,
      ),
    );
  }
}
