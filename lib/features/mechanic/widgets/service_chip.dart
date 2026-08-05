import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

class ServiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? iconColor;

  const ServiceChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandOrange
                : isDark ? AppColors.darkCard : AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: isSelected ? AppColors.brandOrange : context.border,
              width: isSelected ? 0 : 1,
            ),
            boxShadow: isSelected ? AppElevation.shadowBrandLight : (isDark ? null : AppElevation.shadowLow),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppResponsive.scaleIcon(context, 16), color: isSelected ? Colors.white : (iconColor ?? context.textSecondary)),
                SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: AppResponsive.scaleFont(context, 13),
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : context.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
