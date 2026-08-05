import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Reusable marketplace empty state (cart, wishlist, search, filters, orders).
class MarketplaceEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const MarketplaceEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppResponsive.scale(context, 32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: context.textTertiary),
            ),
            SizedBox(height: AppResponsive.scale(context, 20)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: AppResponsive.scaleFont(context, 18),
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppResponsive.scale(context, 8)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppResponsive.scaleFont(context, 13),
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                height: 1.45,
              ),
            ),
            SizedBox(height: AppResponsive.scale(context, 24)),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.shopping_bag_rounded, size: 18),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
