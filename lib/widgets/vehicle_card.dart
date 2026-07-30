import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_helpers.dart';

class VehicleCard extends StatelessWidget {
  final String name;
  final String registration;
  final String fuelType;
  final String? lastService;
  final int? healthScore;
  final bool isDefault;
  final VoidCallback? onTap;
  final VoidCallback? onSetDefault;

  const VehicleCard({
    super.key,
    required this.name,
    required this.registration,
    required this.fuelType,
    this.lastService,
    this.healthScore,
    this.isDefault = false,
    this.onTap,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDefault ? AppColors.brandOrange.withValues(alpha: 0.3) : context.borderSoft,
            width: isDefault ? 1.5 : 1,
          ),
          boxShadow: context.shadowLow,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDefault
                      ? [AppColors.brandOrange, AppColors.brandOrangeDark]
                      : [AppColors.grey100, AppColors.grey200],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _vehicleIcon,
                size: 28,
                color: isDefault ? Colors.white : AppColors.grey500,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandOrangeLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandOrange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    registration,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildChip(context, fuelType),
                      if (lastService != null) ...[
                        const SizedBox(width: 6),
                        _buildChip(context, 'Last: $lastService'),
                      ],
                      if (healthScore != null) ...[
                        const SizedBox(width: 6),
                        _buildHealthChip(healthScore!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.grey300, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.bgTertiary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: context.textTertiary),
      ),
    );
  }

  Widget _buildHealthChip(int score) {
    final color = score >= 80
        ? AppColors.success
        : score >= 50
            ? AppColors.warning
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$score%',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  IconData get _vehicleIcon {
    if (name.toLowerCase().contains('bike') || name.toLowerCase().contains('activa') || name.toLowerCase().contains('scooter')) {
      return Icons.two_wheeler_rounded;
    }
    return Icons.directions_car_rounded;
  }
}
