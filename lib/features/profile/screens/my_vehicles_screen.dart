import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/profile/navigation.dart';
import 'package:mecha_connect/features/profile/providers/profile_provider.dart';
import 'package:mecha_connect/features/profile/widgets/profile_empty.dart';
import 'package:mecha_connect/features/profile/widgets/vehicle_card.dart';
import 'package:mecha_connect/features/profile/widgets/vehicle_form.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// All vehicles registered under the account, with add / edit / default.
class MyVehiclesScreen extends StatelessWidget {
  const MyVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Vehicles',
          style: AppTypography.titleLg.copyWith(color: context.textPrimary),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addVehicle(context),
        backgroundColor: context.accent,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Vehicle'),
      ),
      body: provider.vehicles.isEmpty
          ? ProfileEmptyState(
              icon: Icons.directions_car_outlined,
              title: 'No vehicles yet',
              message: 'Add your first vehicle to keep track of '
                  'insurance, PUC and service due dates.',
              actionLabel: 'Add Vehicle',
              onAction: () => _addVehicle(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base, AppSpacing.sm, AppSpacing.base, 96),
              children: [
                for (final vehicle in provider.vehicles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ProfileVehicleCard(
                      vehicle: vehicle,
                      onTap: () => openVehicleDetail(context, vehicle),
                      onSetDefault: () =>
                          provider.setDefaultVehicle(vehicle.id),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _addVehicle(BuildContext context) async {
    final added = await showVehicleFormSheet(context);
    if (added && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle added')),
      );
    }
  }
}
