import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/home/home_data.dart';

class VehicleCard extends StatelessWidget {
  final VehicleInfo vehicle;

  const VehicleCard({
    super.key,
    this.vehicle = mockVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(
        left: AppResponsive.horizontalPadding(context),
        right: AppResponsive.horizontalPadding(context),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: isDark ? null : AppElevation.shadowHigh,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.brandOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: AppColors.brandOrange,
                  size: 26,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  vehicle.name,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: AppResponsive.scaleFont(context, 18),
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.base),
          Row(
            children: [
              _buildStat(context, 'Health', '${vehicle.healthPercent}%', AppColors.success, vehicle.healthPercent / 100, isDark),
              SizedBox(width: AppSpacing.xs),
              _buildStat(context, 'Fuel', '${vehicle.fuelPercent}%', AppColors.brandOrange, vehicle.fuelPercent / 100, isDark),
              SizedBox(width: AppSpacing.xs),
              _buildSmallStat(context, 'Battery', vehicle.battery, AppColors.brandBlue, isDark),
              SizedBox(width: AppSpacing.xs),
              _buildSmallStat(context, 'Insurance', vehicle.insurance, AppColors.success, isDark),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkSurface : AppColors.grey50).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'Last service: ${vehicle.lastService}',
                  style: TextStyle(
                    fontSize: AppResponsive.scaleFont(context, 12),
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, Color color, double progress, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurface : AppColors.grey50).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppResponsive.scaleFont(context, 11),
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: AppResponsive.scaleFont(context, 18),
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStat(BuildContext context, String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurface : AppColors.grey50).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppResponsive.scaleFont(context, 11),
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: AppResponsive.scaleFont(context, 13),
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs + 2),
            SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}

