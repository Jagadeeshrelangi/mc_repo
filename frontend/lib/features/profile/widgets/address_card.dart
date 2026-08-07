import 'package:flutter/material.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// A saved address row with label, coordinates and default badge.
class ProfileAddressCard extends StatelessWidget {
  final SavedAddress address;
  final VoidCallback? onTap;
  final VoidCallback? onSetDefault;

  const ProfileAddressCard({
    super.key,
    required this.address,
    this.onTap,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${address.label.label} address',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: context.border, width: 1),
            boxShadow: context.shadowLow,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _colorFor(address.label).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(address.label.icon, size: 24, color: _colorFor(address.label)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.label.label,
                          style: AppTypography.titleMd
                              .copyWith(color: context.textPrimary),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 6),
                          _pill(context, 'Default', AppColors.success),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      address.address,
                      style: AppTypography.bodySm
                          .copyWith(color: context.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${address.latitude.toStringAsFixed(4)}, '
                      '${address.longitude.toStringAsFixed(4)}',
                      style: AppTypography.labelSm
                          .copyWith(color: context.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.grey300),
                  if (onSetDefault != null && !address.isDefault) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onSetDefault,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                        child: Text(
                          'Set Default',
                          style: AppTypography.labelSm
                              .copyWith(color: context.accent),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.overline.copyWith(color: color),
      ),
    );
  }

  Color _colorFor(AddressLabel label) {
    switch (label) {
      case AddressLabel.home:
        return AppColors.brandBlue;
      case AddressLabel.office:
        return AppColors.brandOrange;
      case AddressLabel.other:
        return AppColors.success;
    }
  }
}
