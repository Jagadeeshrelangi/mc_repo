import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/features/profile/providers/profile_provider.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// Shows the add/edit vehicle bottom sheet.
///
/// Returns `true` when a vehicle was saved. The write always flows through
/// [ProfileProvider.addVehicle] / [ProfileProvider.saveVehicle].
Future<bool> showVehicleFormSheet(
  BuildContext context, {
  ProfileVehicle? vehicle,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _VehicleFormSheet(vehicle: vehicle),
  );
  return saved ?? false;
}

class _VehicleFormSheet extends StatefulWidget {
  final ProfileVehicle? vehicle;

  const _VehicleFormSheet({this.vehicle});

  @override
  State<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<_VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _registrationController;
  late final TextEditingController _serviceDueKmController;

  late VehicleFuel _fuelType;
  late bool _isDefault;
  DateTime? _insuranceExpiry;
  DateTime? _pucExpiry;
  DateTime? _serviceDueDate;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _brandController = TextEditingController(text: v?.brand ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _registrationController = TextEditingController(text: v?.registration ?? '');
    _serviceDueKmController =
        TextEditingController(text: v?.serviceDueKm?.toString() ?? '');
    _fuelType = v?.fuelType ?? VehicleFuel.petrol;
    _isDefault = v?.isDefault ?? false;
    _insuranceExpiry = v?.insuranceExpiry;
    _pucExpiry = v?.pucExpiry;
    _serviceDueDate = v?.serviceDueDate;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _registrationController.dispose();
    _serviceDueKmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<ProfileProvider>();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final draft = ProfileVehicle(
      id: widget.vehicle?.id ?? 'veh-${DateTime.now().millisecondsSinceEpoch}',
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      registration: _registrationController.text.trim().toUpperCase(),
      fuelType: _fuelType,
      insuranceExpiry: _insuranceExpiry,
      pucExpiry: _pucExpiry,
      serviceDueKm: int.tryParse(_serviceDueKmController.text.trim()),
      serviceDueDate: _serviceDueDate,
      isDefault: _isDefault,
      healthScore: widget.vehicle?.healthScore ?? 80,
    );

    final ok = _isEditing
        ? await provider.saveVehicle(draft)
        : await provider.addVehicle(draft);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.operationError ?? 'Unable to save vehicle')),
      );
    }
  }

  Future<DateTime?> _pickDate(DateTime? current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    return picked;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Vehicle' : 'Add Vehicle',
              style: AppTypography.headlineLg.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Registered under your account',
              style: AppTypography.bodySm.copyWith(color: context.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(
                    controller: _brandController,
                    label: 'Brand',
                    icon: Icons.directions_car_rounded,
                    validator: provider.validateVehicleBrand,
                  ),
                  _field(
                    controller: _modelController,
                    label: 'Model',
                    icon: Icons.model_training_rounded,
                    validator: provider.validateVehicleModel,
                  ),
                  _field(
                    controller: _registrationController,
                    label: 'Registration number',
                    icon: Icons.confirmation_number_outlined,
                    validator: provider.validateRegistration,
                  ),
                  DropdownButtonFormField<VehicleFuel>(
                    value: _fuelType,
                    decoration: _decoration('Fuel type', Icons.local_gas_station_rounded),
                    items: [
                      for (final fuel in VehicleFuel.values)
                        DropdownMenuItem(
                          value: fuel,
                          child: Text(fuel.label),
                        ),
                    ],
                    onChanged: (v) => setState(() => _fuelType = v ?? VehicleFuel.petrol),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _datePickerRow(context, 'Insurance expiry', _insuranceExpiry,
                      (d) => setState(() => _insuranceExpiry = d)),
                  _datePickerRow(context, 'PUC expiry', _pucExpiry,
                      (d) => setState(() => _pucExpiry = d)),
                  _datePickerRow(context, 'Service due date', _serviceDueDate,
                      (d) => setState(() => _serviceDueDate = d)),
                  _field(
                    controller: _serviceDueKmController,
                    label: 'Service due (km)',
                    icon: Icons.speed_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Make this my default vehicle'),
                    value: _isDefault,
                    activeTrackColor: AppColors.brandOrange,
                    onChanged: (v) => setState(() => _isDefault = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isSavingVehicle ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.accent,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                      child: provider.isSavingVehicle
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEditing ? 'Save Changes' : 'Add Vehicle'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: AppTypography.bodyMd.copyWith(color: context.textPrimary),
        decoration: _decoration(label, icon),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: context.textSecondary, size: 20),
      filled: true,
      fillColor: context.bgSecondary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: context.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: context.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.brandOrange, width: 1.6),
      ),
    );
  }

  Widget _datePickerRow(
    BuildContext context,
    String label,
    DateTime? value,
    ValueChanged<DateTime> onPicked,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () async {
          final picked = await _pickDate(value);
          if (picked != null && mounted) onPicked(picked);
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InputDecorator(
          decoration: _decoration(label, Icons.calendar_today_outlined),
          child: Text(
            value == null
                ? 'Not set'
                : '${value.day}/${value.month}/${value.year}',
            style: value == null
                ? AppTypography.bodyMd.copyWith(color: context.textTertiary)
                : AppTypography.bodyMd.copyWith(color: context.textPrimary),
          ),
        ),
      ),
    );
  }
}
