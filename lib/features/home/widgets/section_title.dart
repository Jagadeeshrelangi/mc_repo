import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
        left: AppResponsive.horizontalPadding(context),
        right: AppResponsive.horizontalPadding(context),
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: AppResponsive.scaleFont(context, 20),
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: AppResponsive.scaleFont(context, 13),
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandOrange,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
