import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/marketplace/models/order_models.dart';
import 'package:mecha_connect/services/location_provider.dart';
import 'package:mecha_connect/services/location_service.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/widgets/location_status_banner.dart';

/// Address form bottom sheet used at checkout. Returns the validated
/// [CheckoutAddress] when the user taps Continue, or null when dismissed.
///
/// GPS-first, like every other address screen: on open it runs the shared
/// [LocationService] pipeline (permission → GPS → reverse geocode) and
/// auto-populates the address/pincode/city/state fields, which stay editable.
/// Manual entry is only a fallback for the denied/error states.
Future<CheckoutAddress?> showAddressSheet(BuildContext context) {
  return showModalBottomSheet<CheckoutAddress>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const AddressSheet(),
  );
}

class AddressSheet extends StatefulWidget {
  const AddressSheet({super.key});

  @override
  State<AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<AddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pincode = TextEditingController();
  final _line1 = TextEditingController();
  final _area = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _addressFocusNode = FocusNode();
  final LocationService _locationService = LocationService();

  LocationBannerState _locationStatus = LocationBannerState.idle;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _detect();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pincode.dispose();
    _line1.dispose();
    _area.dispose();
    _city.dispose();
    _state.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  Future<void> _detect() async {
    if (_isDetecting) return;
    _isDetecting = true;
    setState(() => _locationStatus = LocationBannerState.loading);

    final provider = context.read<LocationProvider>();
    try {
      final result = await _locationService.detect(provider: provider);
      if (!mounted) return;
      _applyDetected(result);
    } on LocationDetectException catch (e) {
      if (!mounted) return;
      setState(() => _locationStatus = e.state);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationStatus = LocationBannerState.error);
    } finally {
      _isDetecting = false;
    }
  }

  /// Auto-populates the address fields from the detected location. Every field
  /// stays editable — GPS is a prefill, never a lock-in.
  void _applyDetected(DetectedLocation result) {
    final details = result.details;
    final address = result.address;
    if (address == null || address.isEmpty) {
      setState(() => _locationStatus = LocationBannerState.error);
      return;
    }
    if (details != null && details.street.isNotEmpty) {
      _line1.text = details.street;
      _area.text = details.locality;
    } else {
      _line1.text = address;
    }
    if (details != null && details.city.isNotEmpty) _city.text = details.city;
    if (details != null && details.state.isNotEmpty) _state.text = details.state;
    if (details != null && details.pincode.isNotEmpty) {
      _pincode.text = details.pincode;
    }
    setState(() => _locationStatus = LocationBannerState.success);
  }

  void _enterManually() {
    setState(() => _locationStatus = LocationBannerState.idle);
    FocusScope.of(context).requestFocus(_addressFocusNode);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Address',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              LocationStatusBanner(
                state: _locationStatus,
                isDetecting: _isDetecting,
                onDetect: _detect,
                onEnterManually: _enterManually,
                onOpenSettings: () =>
                    context.read<LocationProvider>().openSettings(),
                onEnableServices: () =>
                    context.read<LocationProvider>().checkAndRequestPermission(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _name,
                      label: 'Full name',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      _phone,
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null ||
                              !RegExp(r'^\d{10}$').hasMatch(v.trim()))
                          ? '10-digit'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(
                _line1,
                label: 'Address',
                icon: Icons.home_outlined,
                focusNode: _addressFocusNode,
                enabled: _locationStatus != LocationBannerState.loading,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _field(_area, label: 'Area / Landmark',
                  enabled: _locationStatus != LocationBannerState.loading),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _pincode,
                      label: 'PIN code',
                      icon: Icons.pin_drop_outlined,
                      keyboardType: TextInputType.number,
                      enabled: _locationStatus != LocationBannerState.loading,
                      validator: (v) => (v == null ||
                              !RegExp(r'^\d{6}$').hasMatch(v.trim()))
                          ? '6-digit'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      _city,
                      label: 'City',
                      enabled: _locationStatus != LocationBannerState.loading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(
                _state,
                label: 'State',
                enabled: _locationStatus != LocationBannerState.loading,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller, {
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    FocusNode? focusNode,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        isDense: true,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: context.border),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final address = _line1.text.trim();
    final area = _area.text.trim();
    Navigator.pop(
      context,
      CheckoutAddress(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        address: area.isEmpty ? address : '$address, $area',
        city: _city.text.trim(),
        state: _state.text.trim(),
        pincode: _pincode.text.trim(),
      ),
    );
  }
}
