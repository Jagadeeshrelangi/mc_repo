import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';

class ClusterIcon {
  final IconData icon;
  final Color color;
  final double size;
  final double dx;
  final double dy;

  const ClusterIcon({
    required this.icon,
    required this.color,
    this.size = 28,
    this.dx = 0,
    this.dy = 0,
  });
}

class OnboardingModel {
  final String title;
  final String description;
  final Color accent;
  final Color accentLight;
  final Color glowColor;
  final List<ClusterIcon> icons;

  const OnboardingModel({
    required this.title,
    required this.description,
    required this.accent,
    required this.accentLight,
    required this.glowColor,
    required this.icons,
  });

  static List<OnboardingModel> get slides => [
        _slide1,
        _slide2,
        _slide3,
        _slide4,
      ];

  static const _slide1 = OnboardingModel(
    title: 'Your Smart Vehicle Companion',
    description:
        'Your one-stop solution for fuel delivery, roadside assistance, AI diagnostics, and genuine vehicle parts.',
    accent: AppColors.brandOrange,
    accentLight: AppColors.brandOrangeLight,
    glowColor: AppColors.brandOrange,
    icons: [
      ClusterIcon(
        icon: Icons.smart_toy_rounded,
        color: AppColors.brandOrange,
        size: 32,
        dx: -0.15,
        dy: -0.15,
      ),
      ClusterIcon(
        icon: Icons.speed_rounded,
        color: AppColors.brandOrangeLight,
        size: 26,
        dx: 0.35,
        dy: -0.1,
      ),
      ClusterIcon(
        icon: Icons.electric_rickshaw_rounded,
        color: AppColors.brandOrange,
        size: 24,
        dx: -0.2,
        dy: 0.3,
      ),
      ClusterIcon(
        icon: Icons.dashboard_rounded,
        color: AppColors.brandOrangeLight,
        size: 22,
        dx: 0.3,
        dy: 0.3,
      ),
    ],
  );

  static const _slide2 = OnboardingModel(
    title: 'Roadside Help in Minutes',
    description:
        'Connect instantly with nearby mechanics and emergency roadside assistance whenever you need help.',
    accent: AppColors.brandBlue,
    accentLight: AppColors.brandBlueLight,
    glowColor: AppColors.brandBlue,
    icons: [
      ClusterIcon(
        icon: Icons.build_rounded,
        color: AppColors.brandBlue,
        size: 32,
        dx: -0.15,
        dy: -0.15,
      ),
      ClusterIcon(
        icon: Icons.support_agent_rounded,
        color: AppColors.brandBlueLight,
        size: 26,
        dx: 0.35,
        dy: -0.1,
      ),
      ClusterIcon(
        icon: Icons.two_wheeler_rounded,
        color: AppColors.brandBlue,
        size: 24,
        dx: -0.2,
        dy: 0.3,
      ),
      ClusterIcon(
        icon: Icons.emergency_rounded,
        color: AppColors.brandBlueLight,
        size: 22,
        dx: 0.3,
        dy: 0.3,
      ),
    ],
  );

  static const _slide3 = OnboardingModel(
    title: 'Everything Your Vehicle Needs',
    description:
        'Fuel, spare parts, servicing, AI assistance, bookings and vehicle care\u2014all from one app.',
    accent: AppColors.success,
    accentLight: AppColors.success,
    glowColor: AppColors.success,
    icons: [
      ClusterIcon(
        icon: Icons.local_gas_station_rounded,
        color: AppColors.success,
        size: 28,
        dx: -0.25,
        dy: -0.2,
      ),
      ClusterIcon(
        icon: Icons.settings_suggest_rounded,
        color: AppColors.success,
        size: 26,
        dx: 0.3,
        dy: -0.15,
      ),
      ClusterIcon(
        icon: Icons.precision_manufacturing_rounded,
        color: AppColors.success,
        size: 24,
        dx: -0.1,
        dy: 0.35,
      ),
      ClusterIcon(
        icon: Icons.map_rounded,
        color: AppColors.success,
        size: 22,
        dx: 0.35,
        dy: 0.25,
      ),
      ClusterIcon(
        icon: Icons.miscellaneous_services_rounded,
        color: AppColors.success,
        size: 22,
        dx: -0.35,
        dy: 0.1,
      ),
    ],
  );

  static const _slide4 = OnboardingModel(
    title: 'Ready to Drive Smarter?',
    description:
        'Experience the future of vehicle assistance with Mecha Connect.',
    accent: AppColors.brandOrange,
    accentLight: AppColors.brandOrangeLight,
    glowColor: AppColors.brandOrange,
    icons: [],
  );
}
