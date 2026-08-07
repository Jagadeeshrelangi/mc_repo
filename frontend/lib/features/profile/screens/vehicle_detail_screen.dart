import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/features/profile/providers/profile_provider.dart';
import 'package:mecha_connect/features/profile/widgets/vehicle_form.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// Full vehicle detail: health, expiry dates, edit / default / delete.
class VehicleDetailScreen extends StatelessWidget {
  final ProfileVehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    // The vehicle may have been removed while this screen was open.
    final current = provider.vehicles.firstWhere(
      (v) => v.id == vehicle.id,
      orElse: () => vehicle,
    );

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          current.name,
          style: AppTypography.titleLg.copyWith(color: context.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit vehicle',
            onPressed: () => _editVehicle(context, current),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Delete vehicle',
            onPressed: () => _deleteVehicle(context, current),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      current.fuelType == VehicleFuel.electric
                          ? Icons.electric_bolt_rounded
                          : Icons.directions_car_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      current.name,
                      style: AppTypography.displaySm.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  current.registration,
                  style: AppTypography.bodyMd.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    _healthBadge(context, current.healthScore),
                    const SizedBox(width: AppSpacing.sm),
                    if (current.isDefault)
                      _whitePill(context, Icons.check_circle_rounded, 'Default'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _section(context, 'Vehicle details'),
          _detailTile(context, 'Fuel type', current.fuelType.label),
          _detailTile(context, 'Insurance expiry',
              _formatDate(current.insuranceExpiry)),
          _detailTile(context, 'PUC expiry', _formatDate(current.pucExpiry)),
          _detailTile(context, 'Service due',
              current.serviceDueKm != null
                  ? '${current.serviceDueKm} km'
                  : '—'),
          _detailTile(context, 'Service due date',
              _formatDate(current.serviceDueDate)),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: current.isDefault
                  ? null
                  : () => provider.setDefaultVehicle(current.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.accent,
                side: BorderSide(color: context.accent.withValues(alpha: 0.5)),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              icon: const Icon(Icons.star_rounded, size: 20),
              label: Text(current.isDefault
                  ? 'Default Vehicle'
                  : 'Set as Default'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthBadge(BuildContext context, int score) {
    final color = score >= 85
        ? AppColors.success
        : score >= 60
            ? AppColors.warning
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            'Health $score/100',
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

  Widget _whitePill(BuildContext context, IconData icon, String text) {
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
            text,
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

  Widget _section(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: AppTypography.titleLg.copyWith(color: context.textPrimary),
      ),
    );
  }

  Widget _detailTile(BuildContext context, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMd.copyWith(color: context.textSecondary),
          ),
          Text(
            value,
            style: AppTypography.titleSm.copyWith(color: context.textPrimary),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _editVehicle(BuildContext context, ProfileVehicle vehicle) async {
    final saved = await showVehicleFormSheet(context, vehicle: vehicle);
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle updated')),
      );
    }
  }

  Future<void> _deleteVehicle(BuildContext context, ProfileVehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove vehicle?'),
        content: Text(
            '${vehicle.name} will be removed from your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final removed = await context.read<ProfileProvider>().deleteVehicle(vehicle.id);
    if (!context.mounted) return;
    if (removed) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.read<ProfileProvider>().operationError ??
                'Unable to remove vehicle')),
      );
    }
  }
}
