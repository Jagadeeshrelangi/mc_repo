import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// Tappable wallet summary card (balance / reward points).
class ProfileWalletCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const ProfileWalletCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.brandOrange,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title $value',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: context.borderSoft, width: 1),
            boxShadow: context.shadowLow,
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
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs + 4),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.grey300),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                value,
                style: AppTypography.displaySm.copyWith(color: color),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: AppTypography.titleSm.copyWith(color: context.textPrimary),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTypography.labelSm.copyWith(color: context.textTertiary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
