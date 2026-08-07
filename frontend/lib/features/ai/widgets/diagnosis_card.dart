import 'package:flutter/material.dart';
import 'package:mecha_connect/features/ai/models/models.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// Premium structured diagnosis result card with severity, causes, cost,
/// recommended action, drive guidance and the module's CTA buttons.
class DiagnosisCard extends StatelessWidget {
  final Diagnosis diagnosis;
  final VoidCallback? onBookMechanic;
  final VoidCallback? onSearchParts;
  final VoidCallback? onFuelRecommendation;

  const DiagnosisCard({
    super.key,
    required this.diagnosis,
    this.onBookMechanic,
    this.onSearchParts,
    this.onFuelRecommendation,
  });

  Color _severityColor(BuildContext context) {
    switch (diagnosis.severity) {
      case SeverityLevel.low:
        return AppColors.success;
      case SeverityLevel.medium:
        return AppColors.warning;
      case SeverityLevel.high:
        return AppColors.error;
      case SeverityLevel.critical:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.border, width: 1),
        boxShadow: context.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, severityColor),
          const SizedBox(height: AppSpacing.base),
          _severityBanner(context, severityColor),
          const SizedBox(height: AppSpacing.lg),
          _section(
            context,
            icon: Icons.search_rounded,
            accent: context.accent,
            title: 'Possible causes',
            child: Column(
              children: [
                for (var i = 0; i < diagnosis.possibleCauses.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}. ',
                          style: AppTypography.bodySm.copyWith(
                            color: context.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            diagnosis.possibleCauses[i],
                            style: AppTypography.bodySm.copyWith(
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _costRow(context),
          const SizedBox(height: AppSpacing.md),
          _section(
            context,
            icon: Icons.assignment_rounded,
            accent: AppColors.brandBlue,
            title: 'Recommended action',
            child: Text(
              diagnosis.recommendedAction,
              style: AppTypography.bodySm.copyWith(
                color: context.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _section(
            context,
            icon: Icons.build_rounded,
            accent: AppColors.success,
            title: 'Recommended service',
            child: Text(
              diagnosis.recommendedService,
              style: AppTypography.titleMd.copyWith(
                color: context.textPrimary,
              ),
            ),
          ),
          if (onBookMechanic != null ||
              onSearchParts != null ||
              onFuelRecommendation != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildCtas(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color severityColor) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(Icons.monitor_heart_rounded, size: 24, color: context.accent),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                diagnosis.vehicleName,
                style: AppTypography.headlineSm.copyWith(
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                diagnosis.problem,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySm.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: severityColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(diagnosis.severity.icon, size: 14, color: severityColor),
              const SizedBox(width: 6),
              Text(
                diagnosis.severity.label,
                style: AppTypography.labelMd.copyWith(
                  color: severityColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _severityBanner(BuildContext context, Color severityColor) {
    final shouldDrive = diagnosis.shouldDrive;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            shouldDrive
                ? Icons.directions_car_rounded
                : Icons.do_not_disturb_alt_rounded,
            color: severityColor,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shouldDrive ? 'Safe to drive' : 'Do not drive',
                  style: AppTypography.titleMd.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  diagnosis.severity.driveAdvice,
                  style: AppTypography.bodySm.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _costRow(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.brandOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: const Icon(
            Icons.currency_rupee_rounded,
            size: 20,
            color: AppColors.brandOrange,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'Estimated cost',
            style: AppTypography.bodySm.copyWith(
              color: context.textSecondary,
            ),
          ),
        ),
        Text(
          '₹${diagnosis.estimatedCost.toStringAsFixed(0)}',
          style: AppTypography.headlineMd.copyWith(
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _section(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.titleSm.copyWith(
                color: context.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildCtas(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (onBookMechanic != null)
          FilledButton.icon(
            onPressed: onBookMechanic,
            icon: const Icon(Icons.support_agent_rounded, size: 18),
            label: const Text('Book Mechanic'),
            style: FilledButton.styleFrom(
              backgroundColor: context.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
        if (onSearchParts != null)
          OutlinedButton.icon(
            onPressed: onSearchParts,
            icon: const Icon(Icons.shopping_bag_rounded, size: 18),
            label: const Text('Search Parts'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.accent,
              side: BorderSide(color: context.accent.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
        if (onFuelRecommendation != null)
          OutlinedButton.icon(
            onPressed: onFuelRecommendation,
            icon: const Icon(Icons.local_gas_station_rounded, size: 18),
            label: const Text('Fuel Recommendation'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandBlue,
              side: BorderSide(
                color: AppColors.brandBlue.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
      ],
    );
  }
}
