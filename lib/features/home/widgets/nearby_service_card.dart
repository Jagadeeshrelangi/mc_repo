import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/features/home/models/home_models.dart';

class NearbyServicesList extends StatelessWidget {
  final List<NearbyService> services;
  final void Function(NearbyService service)? onTap;

  const NearbyServicesList({
    super.key,
    this.services = mockNearbyServices,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.horizontalPadding(context),
        ),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final service = services[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: InkWell(
                onTap: onTap != null ? () => onTap!(service) : null,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: isDark ? null : AppElevation.shadowLow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.brandOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.brandOrange,
                              size: 18,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: service.isOpen
                                  ? AppColors.successLight
                                  : AppColors.warningLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              service.isOpen ? 'Open' : 'Closed',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: service.isOpen
                                    ? AppColors.successDark
                                    : AppColors.warningDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        service.name,
                        style: TextStyle(
                          fontSize: AppResponsive.scaleFont(context, 14),
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (service.rating > 0) ...[
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 3),
                            Text(
                              service.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(Icons.near_me_rounded, size: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              service.distance,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
