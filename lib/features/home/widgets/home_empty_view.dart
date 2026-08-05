import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';

class HomeEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const HomeEmptyView({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.all(AppResponsive.scale(context, 24)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkSurface : AppColors.grey100)
                  .withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              size: 28,
            ),
          ),
          SizedBox(height: AppResponsive.scale(context, 12)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: AppResponsive.scaleFont(context, 15),
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppResponsive.scale(context, 4)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppResponsive.scaleFont(context, 12),
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
