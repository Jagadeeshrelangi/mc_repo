import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/home/home_data.dart';

class RecentActivityList extends StatelessWidget {
  final List<ActivityItem> activities;

  const RecentActivityList({
    super.key,
    this.activities = mockActivity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPadding(context),
      ),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: isDark ? null : AppElevation.shadowLow,
      ),
      child: Column(
        children: activities.map((item) => _buildActivityRow(context, item, isDark)).toList(),
      ),
    );
  }

  Widget _buildActivityRow(BuildContext context, ActivityItem item, bool isDark) {
    final isLast = activities.last == item;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(item.icon, color: item.statusColor, size: 20),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: AppResponsive.scaleFont(context, 14),
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isCompleted
                      ? AppColors.successLight
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    fontSize: AppResponsive.scaleFont(context, 11),
                    fontWeight: FontWeight.w600,
                    color: item.isCompleted
                        ? AppColors.successDark
                        : AppColors.warningDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

