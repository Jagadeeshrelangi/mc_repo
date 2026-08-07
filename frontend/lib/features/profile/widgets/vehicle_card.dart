import 'package:flutter/material.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// A registered vehicle row with health, default badge and due-date warnings.
class ProfileVehicleCard extends StatelessWidget {
  final ProfileVehicle vehicle;
  final VoidCallback? onTap;
  final VoidCallback? onSetDefault;

  const ProfileVehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final dueWarnings = <String>[
      if (vehicle.insuranceExpiry != null &&
          vehicle.insuranceExpiry!.isBefore(DateTime.now().add(const Duration(days: 30))))
        'Insurance due ${_shortDate(vehicle.insuranceExpiry!)}',
      if (vehicle.pucExpiry != null &&
          vehicle.pucExpiry!.isBefore(DateTime.now().add(const Duration(days: 30))))
        'PUC due ${_shortDate(vehicle.pucExpiry!)}',
    ];

    return Semantics(
      button: true,
      label: '${vehicle.name}, ${vehicle.registration}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: context.border, width: 1),
            boxShadow: context.shadowLow,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: context.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  vehicle.fuelType == VehicleFuel.electric
                      ? Icons.electric_bolt_rounded
                      : Icons.directions_car_rounded,
                  size: 26,
                  color: context.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vehicle.name,
                            style: AppTypography.titleMd.copyWith(
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (vehicle.isDefault) ...[
                          const SizedBox(width: 6),
                          _pill(context, 'Default', AppColors.success),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.registration,
                      style: AppTypography.bodySm.copyWith(
                        color: context.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(vehicle.fuelType.icon,
                            size: 12, color: context.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          vehicle.fuelType.label,
                          style: AppTypography.labelSm
                              .copyWith(color: context.textTertiary),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.favorite_rounded,
                            size: 12, color: _healthColor(vehicle.healthScore)),
                        const SizedBox(width: 4),
                        Text(
                          '${vehicle.healthScore}',
                          style: AppTypography.labelSm
                              .copyWith(color: context.textTertiary),
                        ),
                      ],
                    ),
                    if (dueWarnings.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      for (final warning in dueWarnings)
                        Text(
                          warning,
                          style: AppTypography.labelSm
                              .copyWith(color: AppColors.warning),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.grey300),
                  if (onSetDefault != null && !vehicle.isDefault) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onSetDefault,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                        child: Text(
                          'Set Default',
                          style: AppTypography.labelSm
                              .copyWith(color: context.accent),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.overline.copyWith(color: color),
      ),
    );
  }

  Color _healthColor(int score) {
    if (score >= 85) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String _shortDate(DateTime date) {
    return '${date.day} ${_months[date.month - 1]}';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
