import 'package:flutter/material.dart';
import 'package:mecha_connect/starting_screen/models/onboarding_model.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';

class FloatingIconCluster extends StatelessWidget {
  final List<ClusterIcon> icons;
  final Color accent;
  final double containerSize;

  const FloatingIconCluster({
    super.key,
    required this.icons,
    required this.accent,
    this.containerSize = 200,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = AppResponsive.scale(context, containerSize);
    final cardColor = isDark ? AppColors.darkCard : AppColors.white;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildCenterCard(context, cardColor, size),
          ...List.generate(icons.length, (i) {
            final icon = icons[i];
            return Positioned(
              left: icon.dx < 0 ? size * (0.5 + icon.dx) : null,
              right: icon.dx >= 0 ? size * (0.5 - icon.dx) : null,
              top: icon.dy < 0 ? size * (0.5 + icon.dy) : null,
              bottom: icon.dy >= 0 ? size * (0.5 - icon.dy) : null,
              child: _buildFloatingIcon(context, icon, isDark),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCenterCard(BuildContext context, Color cardColor, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cardColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingIcon(
      BuildContext context, ClusterIcon icon, bool isDark) {
    final iconSize = AppResponsive.scaleIcon(context, icon.size);
    final containerSize = AppResponsive.scale(context, icon.size * 1.5);
    final bgColor = isDark
        ? (icon.color.withValues(alpha: 0.15))
        : (icon.color.withValues(alpha: 0.1));

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon.icon, size: iconSize, color: icon.color),
    );
  }
}
