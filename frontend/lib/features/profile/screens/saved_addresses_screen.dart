import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/features/profile/providers/profile_provider.dart';
import 'package:mecha_connect/features/profile/widgets/address_card.dart';
import 'package:mecha_connect/features/profile/widgets/address_form.dart';
import 'package:mecha_connect/features/profile/widgets/profile_empty.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// Saved delivery / pickup addresses with the same GPS auto-detect flow the
/// Mechanic and Fuel screens use.
class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

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
          'Saved Addresses',
          style: AppTypography.titleLg.copyWith(color: context.textPrimary),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addAddress(context),
        backgroundColor: context.accent,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Address'),
      ),
      body: provider.addresses.isEmpty
          ? ProfileEmptyState(
              icon: Icons.location_on_outlined,
              title: 'No saved addresses',
              message: 'Save your home and office addresses to make '
                  'booking faster.',
              actionLabel: 'Add Address',
              onAction: () => _addAddress(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base, AppSpacing.sm, AppSpacing.base, 96),
              children: [
                for (final address in provider.addresses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ProfileAddressCard(
                      address: address,
                      onSetDefault: () =>
                          provider.setDefaultAddress(address.id),
                      onTap: () => _editAddress(context, address),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _addAddress(BuildContext context) async {
    final added = await showAddressFormSheet(context);
    if (added && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address added')),
      );
    }
  }

  Future<void> _editAddress(BuildContext context, SavedAddress address) async {
    final saved = await showAddressFormSheet(context, address: address);
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address updated')),
      );
    }
  }
}
