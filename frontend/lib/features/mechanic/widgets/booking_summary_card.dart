import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

class BookingSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const BookingSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: AppResponsive.scale(context, 40),
            height: AppResponsive.scale(context, 40),
            decoration: BoxDecoration(
              color: AppColors.brandOrangeSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: AppResponsive.scaleIcon(context, 20), color: AppColors.brandOrange),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: context.textTertiary, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: AppResponsive.scaleFont(context, 14), fontWeight: FontWeight.w600, color: context.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
