import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/features/home/models/home_models.dart';

class QuickServicesGrid extends StatelessWidget {
  final List<QuickService> services;
  final void Function(QuickService service)? onTap;

  const QuickServicesGrid({
    super.key,
    this.services = mockQuickServices,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPadding(context) - 4,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            services
                .map(
                  (service) => _QuickServiceItem(
                    service: service,
                    onTap: onTap != null ? () => onTap!(service) : null,
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _QuickServiceItem extends StatelessWidget {
  final QuickService service;
  final VoidCallback? onTap;

  const _QuickServiceItem({required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = AppResponsive.horizontalPadding(context);
    final availableWidth = screenWidth - (horizontalPadding * 2) - 8;
    final crossAxisCount =
        screenWidth >= 600 ? 4 : (screenWidth >= 340 ? 3 : 2);
    final itemWidth =
        (availableWidth - (crossAxisCount - 1) * 8) / crossAxisCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: itemWidth,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: isDark ? null : AppElevation.shadowLow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: service.bgColor,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(service.icon, color: service.color, size: 22),
                ),
                SizedBox(height: AppSpacing.xs + 2),
                Text(
                  service.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppResponsive.scaleFont(context, 12),
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
