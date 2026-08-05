import 'package:flutter/material.dart';
import 'package:mecha_connect/features/profile/models/user_profile.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// Maps an avatar key to a Material icon (mock avatar choices).
///
/// `null` or unknown keys fall back to the default person avatar.
IconData profileAvatarIcon(String? avatarUrl) {
  switch (avatarUrl) {
    case 'avatar-bike':
      return Icons.two_wheeler_rounded;
    case 'avatar-car':
      return Icons.directions_car_rounded;
    case 'avatar-helmet':
      return Icons.sports_motorsports_rounded;
    case 'avatar-tools':
      return Icons.build_rounded;
    default:
      return Icons.person_rounded;
  }
}

/// Large orange-gradient account header shown at the top of the Profile home.
class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final int rewardPoints;
  final VoidCallback? onEdit;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.rewardPoints,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, 0),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(context),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: AppTypography.displaySm.copyWith(
                        color: Colors.white,
                        fontSize: AppResponsive.scaleFont(context, 20),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email,
                      style: AppTypography.bodySm.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.phone,
                      style: AppTypography.bodySm.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                _editButton(context),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _badge(context, profile.membershipTier.icon, profile.membershipTier.label),
              _badge(context, Icons.star_rounded, '$rewardPoints pts'),
              _badge(
                context,
                Icons.calendar_today_rounded,
                _joinedLabel(profile.joinedDate),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(BuildContext context) {
    return Semantics(
      label: 'Profile photo',
      image: true,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
        ),
        child: Icon(profileAvatarIcon(profile.avatarUrl), size: 32, color: Colors.white),
      ),
    );
  }

  Widget _editButton(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Edit profile',
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _badge(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _joinedLabel(DateTime joinedDate) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[joinedDate.month - 1]} ${joinedDate.year}';
  }
}
