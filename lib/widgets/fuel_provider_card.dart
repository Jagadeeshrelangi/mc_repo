import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

class FuelProviderCard extends StatelessWidget {
  final String name;
  final String brand;
  final String? distance;
  final String? eta;
  final double? rating;
  final bool isVerified;
  final bool isAvailable;
  final VoidCallback? onCall;
  final VoidCallback? onTap;

  const FuelProviderCard({
    super.key,
    required this.name,
    required this.brand,
    this.distance,
    this.eta,
    this.rating,
    this.isVerified = false,
    this.isAvailable = true,
    this.onCall,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: context.border, width: 1),
          boxShadow: context.shadowLow,
        ),
        child: Row(
          children: [
            // Brand avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_brandIcon, size: 24, color: _brandColor),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, size: 14, color: AppColors.brandBlue),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    brand,
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (rating != null) ...[
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (distance != null && distance!.isNotEmpty) ...[
                        Icon(Icons.location_on_outlined, size: 12, color: context.textTertiary),
                        const SizedBox(width: 2),
                        Text(distance!, style: TextStyle(fontSize: 11, color: context.textSecondary)),
                        const SizedBox(width: 8),
                      ],
                      if (eta != null) ...[
                        Icon(Icons.schedule, size: 12, color: context.textTertiary),
                        const SizedBox(width: 2),
                        Text(eta!, style: TextStyle(fontSize: 11, color: context.textSecondary)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Availability / Call
            if (isAvailable && onCall != null)
              GestureDetector(
                onTap: onCall,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.phone_rounded, size: 18, color: AppColors.success),
                ),
              ),
            if (!isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Closed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
              ),
          ],
        ),
      ),
    );
  }

  Color get _brandColor {
    switch (brand.toLowerCase()) {
      case 'indian oil': return const Color(0xFF004E8E);
      case 'hp': return const Color(0xFF007504);
      case 'reliance': return const Color(0xFF895200);
      case 'bpcl': return const Color(0xFF003967);
      case 'shell': return const Color(0xFF9B5E02);
      default: return AppColors.brandOrange;
    }
  }

  IconData get _brandIcon {
    return Icons.local_gas_station_rounded;
  }
}
