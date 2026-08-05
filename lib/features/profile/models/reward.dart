import 'package:flutter/material.dart';
import 'user_profile.dart';

/// Why a reward was granted / spent.
enum RewardType {
  earned,
  redeemed,
  referral,
  achievement;

  String get label => switch (this) {
        RewardType.earned => 'Earned',
        RewardType.redeemed => 'Redeemed',
        RewardType.referral => 'Referral',
        RewardType.achievement => 'Achievement',
      };
}

/// A single reward history entry.
class Reward {
  final String id;
  final String title;
  final String subtitle;
  final int points;
  final RewardType type;
  final String date;
  final IconData? icon;

  const Reward({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.type,
    required this.date,
    this.icon,
  });
}

/// Progress toward the next membership tier.
class RewardTierProgress {
  final MembershipTier currentTier;
  final MembershipTier nextTier;
  final int currentPoints;
  final int pointsToNext;
  final List<String> benefits;

  const RewardTierProgress({
    required this.currentTier,
    required this.nextTier,
    required this.currentPoints,
    required this.pointsToNext,
    required this.benefits,
  });

  double get progress => pointsToNext == 0
      ? 1
      : (currentPoints / (currentPoints + pointsToNext)).clamp(0.0, 1.0);
}

/// Full rewards snapshot returned by the mock backend.
class RewardsData {
  final int redeemablePoints;
  final int totalEarned;
  final List<Reward> rewards;
  final List<String> achievements;
  final String referralCode;
  final int referralRewardPoints;
  final RewardTierProgress tierProgress;

  const RewardsData({
    required this.redeemablePoints,
    required this.totalEarned,
    required this.rewards,
    required this.achievements,
    required this.referralCode,
    required this.referralRewardPoints,
    required this.tierProgress,
  });
}
