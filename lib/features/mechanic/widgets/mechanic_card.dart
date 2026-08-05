import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/mechanic/mock_data.dart';

enum MechanicCardVariant { full, compact }

class MechanicCard extends StatelessWidget {
  final MechanicInfo mechanic;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onViewProfile;
  final MechanicCardVariant variant;
  final double? width;

  const MechanicCard({
    super.key,
    required this.mechanic,
    this.onTap,
    this.onCall,
    this.onViewProfile,
    this.variant = MechanicCardVariant.full,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: context.borderSoft, width: 0.5),
            boxShadow: context.shadowLow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhoto(context),
              SizedBox(width: AppSpacing.md),
              Expanded(child: _buildInfo(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(BuildContext context) {
    return Container(
      width: AppResponsive.scale(context, variant == MechanicCardVariant.compact ? 52 : 64),
      height: AppResponsive.scale(context, variant == MechanicCardVariant.compact ? 52 : 64),
      decoration: BoxDecoration(
        color: AppColors.brandOrangeSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.person_rounded, size: AppResponsive.scaleIcon(context, variant == MechanicCardVariant.compact ? 26 : 32), color: AppColors.brandOrange),
          if (mechanic.isVerified)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.brandOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 10, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                mechanic.name,
                style: TextStyle(
                  fontSize: AppResponsive.scaleFont(context, variant == MechanicCardVariant.compact ? 14 : 15),
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (mechanic.isVerified)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.verified_rounded, size: AppResponsive.scaleIcon(context, 14), color: AppColors.brandOrange),
              ),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                '${mechanic.distanceKm.toStringAsFixed(1)} km',
                style: TextStyle(fontSize: 11, color: context.textTertiary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xxs),
        Row(
          children: [
            RatingBadge(rating: mechanic.rating, reviewCount: mechanic.reviewCount, compact: variant == MechanicCardVariant.compact),
            SizedBox(width: AppSpacing.sm),
            Text(
              '${mechanic.experienceYears}yrs',
              style: TextStyle(fontSize: 11, color: context.textSecondary),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xxs),
        if (!mechanic.isAvailable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('Unavailable', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.error)),
          )
        else
          Row(
            children: [
              Container(
                width: 7, height: 7,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              ),
              SizedBox(width: 4),
              Flexible(
                child: Text('Available', style: TextStyle(fontSize: 11, color: AppColors.success), overflow: TextOverflow.ellipsis),
              ),
              SizedBox(width: 4),
              Text('₹${mechanic.priceStarting.toStringAsFixed(0)}+', style: TextStyle(fontSize: AppResponsive.scaleFont(context, variant == MechanicCardVariant.compact ? 13 : 14), fontWeight: FontWeight.w700, color: AppColors.brandOrange)),
            ],
          ),
        if (variant == MechanicCardVariant.full && mechanic.isAvailable) ...[
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: onViewProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.isDark ? AppColors.darkCard : AppColors.grey50,
                      foregroundColor: context.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: context.border, width: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: Text('View Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 48,
                height: 36,
                child: ElevatedButton(
                  onPressed: onCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(Icons.phone_rounded, size: 18),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class RatingBadge extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final bool compact;

  const RatingBadge({super.key, required this.rating, this.reviewCount = 0, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: compact ? 14 : AppResponsive.scaleIcon(context, 16), color: Color(0xFFF59E0B)),
        SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(fontSize: compact ? 12 : AppResponsive.scaleFont(context, 13), fontWeight: FontWeight.w700, color: context.textPrimary),
        ),
        if (reviewCount > 0) ...[
          SizedBox(width: 2),
          Text(
            '($reviewCount)',
            style: TextStyle(fontSize: 10, color: context.textTertiary),
          ),
        ],
      ],
    );
  }
}


