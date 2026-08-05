import 'package:flutter/material.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// A reward history row with signed points.
class ProfileRewardCard extends StatelessWidget {
  final Reward reward;

  const ProfileRewardCard({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    final isPositive = reward.type != RewardType.redeemed;
    final color = isPositive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(reward.icon ?? _defaultIcon(reward.type), size: 22, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: AppTypography.titleMd.copyWith(color: context.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  reward.subtitle,
                  style: AppTypography.bodySm.copyWith(color: context.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${reward.type.label} · ${reward.date}',
                  style: AppTypography.labelSm.copyWith(color: context.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${isPositive ? '+' : '−'}${reward.points}',
            style: AppTypography.titleLg.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _defaultIcon(RewardType type) {
    switch (type) {
      case RewardType.earned:
        return Icons.add_circle_rounded;
      case RewardType.redeemed:
        return Icons.redeem_rounded;
      case RewardType.referral:
        return Icons.person_add_rounded;
      case RewardType.achievement:
        return Icons.emoji_events_rounded;
    }
  }
}
