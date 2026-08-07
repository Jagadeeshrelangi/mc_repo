import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/features/profile/providers/profile_provider.dart';
import 'package:mecha_connect/services/location_provider.dart' as loc;
import 'package:mecha_connect/services/location_service.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// Shows the add/edit saved-address bottom sheet.
///
/// Mirrors the Mechanic / Fuel GPS flow exactly: "Detect Current Location"
/// runs permission → GPS → reverse geocode and auto-fills the address. Manual
/// entry stays available for every non-success state.
Future<bool> showAddressFormSheet(
  BuildContext context, {
  SavedAddress? address,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AddressFormSheet(address: address),
  );
  return saved ?? false;
}

class _AddressFormSheet extends StatefulWidget {
  final SavedAddress? address;

  const _AddressFormSheet({this.address});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  late AddressLabel _label;
  late bool _isDefault;
  LocationBannerState _detectState = LocationBannerState.idle;
  String? _detectError;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _addressController = TextEditingController(text: a?.address ?? '');
    _latController = TextEditingController(
        text: a?.latitude.toStringAsFixed(6) ?? '');
    _lngController = TextEditingController(
        text: a?.longitude.toStringAsFixed(6) ?? '');
    _label = a?.label ?? AddressLabel.home;
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    final locationProvider = context.read<loc.LocationProvider>();
    setState(() {
      _detectState = LocationBannerState.loading;
      _detectError = null;
    });

    try {
      final detected =
          await LocationService().detect(provider: locationProvider);
      if (!mounted) return;
      setState(() {
        _detectState = LocationBannerState.success;
        _addressController.text = detected.address ?? '';
        if (detected.latLng != null) {
          _latController.text =
              detected.latLng!.latitude.toStringAsFixed(6);
          _lngController.text =
              detected.latLng!.longitude.toStringAsFixed(6);
        }
      });
    } on LocationDetectException catch (e) {
      if (!mounted) return;
      setState(() {
        _detectState = e.state;
        _detectError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _detectState = LocationBannerState.error;
        _detectError = 'Unable to determine your location.';
      });
    }
  }

  Future<void> _save() async {
    final provider = context.read<ProfileProvider>();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final draft = SavedAddress(
      id: widget.address?.id ?? 'addr-${DateTime.now().millisecondsSinceEpoch}',
      label: _label,
      address: _addressController.text.trim(),
      latitude: double.tryParse(_latController.text.trim()) ?? 0,
      longitude: double.tryParse(_lngController.text.trim()) ?? 0,
      isDefault: _isDefault,
    );

    final ok = _isEditing
        ? await provider.saveAddress(draft)
        : await provider.addAddress(draft);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.operationError ?? 'Unable to save address')),
      );
    }
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
              _isEditing ? 'Edit Address' : 'Add Address',
              style: AppTypography.headlineLg.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Used for pickup and delivery',
              style: AppTypography.bodySm.copyWith(color: context.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<AddressLabel>(
              segments: [
                for (final label in AddressLabel.values)
                  ButtonSegment(
                    value: label,
                    label: Text(label.label),
                    icon: Icon(label.icon, size: 16),
                  ),
              ],
              selected: {_label},
              onSelectionChanged: (s) => setState(() => _label = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            _detectBanner(context),
            const SizedBox(height: AppSpacing.sm),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _addressField(context),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _latLngField(
                            _latController, 'Latitude',
                            Icons.south_rounded),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _latLngField(
                            _lngController, 'Longitude',
                            Icons.east_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Make this my default address'),
                    value: _isDefault,
                    activeTrackColor: AppColors.brandOrange,
                    onChanged: (v) => setState(() => _isDefault = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isSavingAddress ? null : _save,
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
                      child: provider.isSavingAddress
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEditing ? 'Save Changes' : 'Add Address'),
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

  Widget _detectBanner(BuildContext context) {
    switch (_detectState) {
      case LocationBannerState.idle:
        return _detectButton(context, false);
      case LocationBannerState.loading:
        return _detectButton(context, true);
      case LocationBannerState.success:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Location detected',
                  style: AppTypography.titleSm
                      .copyWith(color: AppColors.success),
                ),
              ),
            ],
          ),
        );
      case LocationBannerState.denied:
      case LocationBannerState.deniedForever:
      case LocationBannerState.serviceDisabled:
      case LocationBannerState.error:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _detectError ?? 'Unable to determine your location.',
                style: AppTypography.bodySm.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _openSettings(context),
                      icon: const Icon(Icons.settings_rounded, size: 18),
                      label: const Text('Open Settings'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.accent,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _detectLocation,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try again'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  Widget _detectButton(BuildContext context, bool loading) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: loading ? null : _detectLocation,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.accent,
          side: BorderSide(color: context.accent.withValues(alpha: 0.5)),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location_rounded, size: 20),
        label: Text(loading
            ? 'Detecting…'
            : 'Detect Current Location'),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    final locationProvider = context.read<loc.LocationProvider>();
    await locationProvider.openSettings();
  }

  Widget _addressField(BuildContext context) {
    return TextFormField(
      controller: _addressController,
      maxLines: 3,
      validator: context.read<ProfileProvider>().validateAddress,
      style: AppTypography.bodyMd.copyWith(color: context.textPrimary),
      decoration: InputDecoration(
        labelText: 'Address',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 60),
          child: Icon(Icons.place_outlined,
              color: AppColors.brandOrange, size: 20),
        ),
        alignLabelWithHint: true,
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
          borderSide:
              const BorderSide(color: AppColors.brandOrange, width: 1.6),
        ),
      ),
    );
  }

  Widget _latLngField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTypography.bodyMd.copyWith(color: context.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: context.textSecondary, size: 18),
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
          borderSide:
              const BorderSide(color: AppColors.brandOrange, width: 1.6),
        ),
      ),
    );
  }
}
