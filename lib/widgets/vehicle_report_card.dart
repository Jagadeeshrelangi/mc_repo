import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_helpers.dart';
import 'severity_badge.dart';

class VehicleReportCard extends StatelessWidget {
  final String vehicleType;
  final String fault;
  final String? severity;
  final String? estimatedCost;
  final String? repairTime;
  final String? date;
  final VoidCallback? onTap;

  const VehicleReportCard({
    super.key,
    required this.vehicleType,
    required this.fault,
    this.severity,
    this.estimatedCost,
    this.repairTime,
    this.date,
    this.onTap,
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
          border: Border.all(color: context.border, width: 1),
          boxShadow: context.shadowLow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brandBlue, AppColors.brandBlueDark],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _vehicleIcon,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fault,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (severity != null) ...[
                        const SizedBox(width: 8),
                        SeverityBadge.fromString(severity: severity!, showLabel: false),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        vehicleType,
                        style: TextStyle(fontSize: 11, color: context.textTertiary),
                      ),
                      if (estimatedCost != null) ...[
                        const SizedBox(width: 8),
                        Text('·', style: TextStyle(color: context.textTertiary)),
                        const SizedBox(width: 8),
                        Text(
                          '₹$estimatedCost',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                      if (date != null) ...[
                        const SizedBox(width: 8),
                        Text('·', style: TextStyle(color: context.textTertiary)),
                        const SizedBox(width: 8),
                        Text(
                          date!,
                          style: TextStyle(fontSize: 11, color: context.textTertiary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  IconData get _vehicleIcon {
    switch (vehicleType.toLowerCase()) {
      case 'bike': return Icons.two_wheeler_rounded;
      case 'car': return Icons.directions_car_rounded;
      case 'truck': return Icons.local_shipping_rounded;
      default: return Icons.build_rounded;
    }
  }
}
