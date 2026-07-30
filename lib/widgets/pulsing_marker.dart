import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum MarkerType { user, mechanic, fuel, destination }

class PulsingMarker extends StatelessWidget {
  final AnimationController controller;
  final MarkerType type;
  final String? label;

  const PulsingMarker({
    super.key,
    required this.controller,
    this.type = MarkerType.user,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final pulseSize = 36.0 + (controller.value * 12);
        final pulseOpacity = (1.0 - controller.value) * 0.4;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring
            Container(
              width: pulseSize,
              height: pulseSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pulseColor.withValues(alpha: pulseOpacity),
              ),
            ),
            // Marker icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _iconBgColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(_iconData, size: 18, color: Colors.white),
            ),
          ],
        );
      },
    );
  }

  Color get _pulseColor {
    switch (type) {
      case MarkerType.user:
        return AppColors.brandBlue;
      case MarkerType.mechanic:
        return AppColors.brandOrange;
      case MarkerType.fuel:
        return AppColors.success;
      case MarkerType.destination:
        return AppColors.error;
    }
  }

  Color get _iconBgColor {
    switch (type) {
      case MarkerType.user:
        return AppColors.brandBlue;
      case MarkerType.mechanic:
        return AppColors.brandOrange;
      case MarkerType.fuel:
        return AppColors.success;
      case MarkerType.destination:
        return AppColors.error;
    }
  }

  IconData get _iconData {
    switch (type) {
      case MarkerType.user:
        return Icons.person_rounded;
      case MarkerType.mechanic:
        return Icons.build_rounded;
      case MarkerType.fuel:
        return Icons.local_gas_station_rounded;
      case MarkerType.destination:
        return Icons.location_on_rounded;
    }
  }
}
