import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/features/profile/providers/profile_provider.dart';
import 'package:mecha_connect/features/profile/widgets/profile_loading.dart';
import 'package:mecha_connect/features/profile/widgets/reward_card.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// Reward points, tier progress, achievements and the referral program.
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final rewards = provider.rewards;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Rewards',
          style: AppTypography.titleLg.copyWith(color: context.textPrimary),
        ),
      ),
      body: rewards == null
          ? const ProfileLoadingState()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                _pointsCard(context, rewards),
                const SizedBox(height: AppSpacing.lg),
                _tierCard(context, rewards.tierProgress),
                const SizedBox(height: AppSpacing.lg),
                _referralCard(context, rewards),
                if (rewards.achievements.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _sectionTitle(context, 'Achievements'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final achievement in rewards.achievements)
                        _achievementChip(context, achievement),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _sectionTitle(context, 'Reward history'),
                for (final reward in rewards.rewards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ProfileRewardCard(reward: reward),
                  ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
    );
  }

  Widget _pointsCard(BuildContext context, RewardsData rewards) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Redeemable Points',
                  style: AppTypography.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${rewards.redeemablePoints}',
                  style: AppTypography.displayLg.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${rewards.totalEarned} lifetime points',
                  style: AppTypography.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded,
                size: 32, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _tierCard(BuildContext context, RewardTierProgress tier) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tier.currentTier.label,
                style: AppTypography.titleMd.copyWith(color: context.textPrimary),
              ),
              Text(
                '${tier.currentPoints}/${tier.currentPoints + tier.pointsToNext}',
                style: AppTypography.labelSm
                    .copyWith(color: context.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            child: LinearProgressIndicator(
              value: tier.progress,
              minHeight: 8,
              backgroundColor: context.bgTertiary,
              color: AppColors.brandOrange,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${tier.pointsToNext} more points to ${tier.nextTier.label}',
            style: AppTypography.bodySm.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final benefit in tier.benefits)
                _benefitChip(context, benefit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _benefitChip(BuildContext context, String benefit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 13, color: AppColors.brandOrange),
          const SizedBox(width: 4),
          Text(
            benefit,
            style: AppTypography.labelSm.copyWith(color: context.accent),
          ),
        ],
      ),
    );
  }

  Widget _referralCard(BuildContext context, RewardsData rewards) {
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
              color: AppColors.brandBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded,
                size: 22, color: AppColors.brandBlue),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Refer & earn ${rewards.referralRewardPoints} points',
                  style: AppTypography.titleMd.copyWith(color: context.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Share your code with friends',
                  style: AppTypography.bodySm
                      .copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: rewards.referralCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Referral code ${rewards.referralCode} copied')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(
              rewards.referralCode,
              style: AppTypography.titleSm
                  .copyWith(color: AppColors.brandOrange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievementChip(BuildContext context, String achievement) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded,
              size: 16, color: AppColors.warning),
          const SizedBox(width: 6),
          Text(
            achievement,
            style: AppTypography.labelSm
                .copyWith(color: AppColors.warning),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.headlineMd.copyWith(color: context.textPrimary),
      ),
    );
  }
}
