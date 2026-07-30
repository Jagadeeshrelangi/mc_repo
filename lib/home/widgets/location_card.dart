import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/home/home_data.dart';

class LocationCard extends StatelessWidget {
  final LocationInfo location;

  const LocationCard({
    super.key,
    this.location = mockLocation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(
        left: AppResponsive.horizontalPadding(context),
        right: AppResponsive.horizontalPadding(context),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: isDark ? null : AppElevation.shadowLow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.brandOrange,
              size: 22,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivering to',
                  style: TextStyle(
                    fontSize: AppResponsive.scaleFont(context, 12),
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  location.fullAddress,
                  style: TextStyle(
                    fontSize: AppResponsive.scaleFont(context, 15),
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkSurface : AppColors.grey100).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

