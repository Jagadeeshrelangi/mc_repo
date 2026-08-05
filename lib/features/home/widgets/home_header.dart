import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/features/home/models/home_models.dart';

class HomeHeader extends StatelessWidget {
  final UserProfile user;
  final VoidCallback? onNotificationsTap;

  const HomeHeader({
    super.key,
    this.user = const UserProfile(),
    this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPadding(context),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.brandOrange.withValues(alpha: 0.15),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: AppResponsive.scaleFont(context, 22),
                fontWeight: FontWeight.w700,
                color: AppColors.brandOrange,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${user.greeting} ',
                      style: TextStyle(
                        fontSize: AppResponsive.scaleFont(context, 14),
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\u{1F44B}',
                      style: TextStyle(fontSize: AppResponsive.scaleFont(context, 16)),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  user.name,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: AppResponsive.scaleFont(context, 24),
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isDark ? null : AppElevation.shadowLow,
            ),
            child: IconButton(
              onPressed: onNotificationsTap,
              icon: const Icon(Icons.notifications_outlined),
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              iconSize: 24,
              padding: EdgeInsets.zero,
              tooltip: 'Notifications',
              splashRadius: 22,
            ),
          ),
        ],
      ),
    );
  }
}
