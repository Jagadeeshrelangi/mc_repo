import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mecha_connect/services/location_service.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/widgets/app_loading.dart';
import 'package:mecha_connect/widgets/location_status_banner.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/fuel_provider.dart';
import '../widgets/widgets.dart';
import 'payment_screen.dart';

/// Booking wizard shell.
///
/// Owns exactly ONE piece of state: the current step index. All booking data
/// (fuel, quantity, vehicle, location, address, pincode, station, price) lives
/// in [FuelProvider]; this screen only reads it and writes back through the
/// provider. Steps are stateless views; the only local State in the wizard are
/// the text-edit surfaces ([_VehicleStep], [_LocationStep]), which hold
/// controllers purely as editing mirrors — never as a source of truth.
class FuelBookingScreen extends StatefulWidget {
  const FuelBookingScreen({super.key});

  @override
  State<FuelBookingScreen> createState() => _FuelBookingScreenState();
}

class _FuelBookingScreenState extends State<FuelBookingScreen> {
  int _currentStep = 0;

  static const List<String> _stepLabels = [
    'Fuel',
    'Vehicle',
    'Location',
    'Station',
    'Review',
  ];

  @override
  void initState() {
    super.initState();
    // The provider is the single source of truth: fuel, quantity, vehicle,
    // location, station and price all live there. This screen only owns the
    // current step index, so initState performs no writes of its own. When the
    // wizard is opened before data has loaded (defensive fallback only — the
    // home screen always loads first), kick the load from a microtask so no
    // provider notification fires during this build phase.
    final provider = context.read<FuelProvider>();
    if (provider.state == FuelScreenState.initial) {
      scheduleMicrotask(provider.loadHome);
    }
  }

  // ── Step navigation ──────────────────────────────────────────────────

  Future<void> _nextStep() async {
    final provider = context.read<FuelProvider>();
    switch (_currentStep) {
      case 0:
        if (provider.selectedFuelType == null) {
          _showSnack('Please select a fuel type');
          return;
        }
        break;
      case 1:
        if (provider.selectedVehicle == null) {
          _showSnack('Please select or add a vehicle');
          return;
        }
        setState(() => _currentStep++);
        if (provider.locationStatus == LocationBannerState.idle &&
            provider.deliveryLocation == null) {
          provider.detectDeliveryLocation();
        }
        return;
      case 2:
        // Detection is still running — the address is about to be filled.
        // Swallow the press instead of showing a false "enter address" error
        // (whose floating snack would otherwise hover over the Continue bar).
        if (provider.isDetectingLocation ||
            provider.locationStatus == LocationBannerState.loading) {
          return;
        }
        final address = provider.deliveryAddress;
        if (address.isEmpty) {
          _showSnack('Please enter your delivery address');
          return;
        }
        final pincode = provider.deliveryPincode;
        if (pincode.isNotEmpty && !address.contains(pincode)) {
          provider.setDeliveryAddress('$address, $pincode');
        }
        setState(() => _currentStep++);
        await provider.fetchStations();
        return;
      case 3:
        if (provider.selectedStation == null) {
          _showSnack('Please select a fuel station');
          return;
        }
        break;
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _placeOrder() async {
    final provider = context.read<FuelProvider>();
    final ok = await provider.placeOrder();
    if (!mounted) return;
    if (!ok) {
      _showSnack(
        provider.errorMessage ?? 'Couldn\'t place the order. Please try again.',
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PaymentScreen()),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FuelProvider>();
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        title: const Text('Fuel Booking'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed:
              _currentStep > 0 ? _prevStep : () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: _buildStepContent(context, provider),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, provider),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.surface,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_stepLabels.length * 2 - 1, (i) {
            if (i.isOdd) {
              return Container(
                width: 24,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color:
                    i ~/ 2 < _currentStep
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
              );
            }
            final stepIndex = i ~/ 2;
            final isActive = stepIndex <= _currentStep;
            final isCurrent = stepIndex == _currentStep;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isCurrent ? 32 : 28,
                  height: isCurrent ? 32 : 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        color:
                            isActive
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _stepLabels[stepIndex],
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isCurrent
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, FuelProvider provider) {
    switch (_currentStep) {
      case 0:
        return _buildFuelStep(context, provider);
      case 1:
        return _VehicleStep(provider: provider);
      case 2:
        return _LocationStep(provider: provider);
      case 3:
        return _buildStationStep(context, provider);
      case 4:
        return _buildReviewStep(context, provider);
      default:
        return const SizedBox();
    }
  }

  // ── Step: Fuel (stateless — reads provider only) ─────────────────────

  Widget _buildFuelStep(BuildContext context, FuelProvider provider) {
    final theme = Theme.of(context);

    if (provider.state == FuelScreenState.loading ||
        provider.state == FuelScreenState.initial) {
      return const SizedBox(
        height: 240,
        child: AppLoading(message: 'Loading fuel types...'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Fuel Type',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the fuel type for your vehicle',
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.textTertiary,
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < provider.fuelTypes.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                FuelTypeCard(
                  fuelType: provider.fuelTypes[i],
                  isSelected:
                      provider.selectedFuelType == provider.fuelTypes[i],
                  onTap: () => provider.selectFuelType(provider.fuelTypes[i]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        QuantitySelector(
          quantity: provider.quantity,
          onChanged: provider.setQuantity,
        ),
        if (provider.priceEstimate != null) ...[
          const SizedBox(height: 20),
          PriceBreakdown(estimate: provider.priceEstimate!),
        ],
      ],
    );
  }

  // ── Step: Station (stateless — reads provider only) ──────────────────

  Widget _buildStationStep(BuildContext context, FuelProvider provider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Fuel Station',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fuel stations near your location',
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.textTertiary,
          ),
        ),
        const SizedBox(height: 20),
        switch (provider.state) {
          FuelScreenState.loading || FuelScreenState.initial => const SizedBox(
            height: 240,
            child: AppLoading(message: 'Finding fuel stations...'),
          ),
          FuelScreenState.error => FuelErrorState(
            icon: Icons.local_gas_station_rounded,
            title: 'Couldn\'t load fuel stations',
            message: provider.errorMessage ?? 'Please try again.',
            retryLabel: 'Retry',
            onRetry: provider.fetchStations,
          ),
          FuelScreenState.empty => FuelEmptyState(
            icon: Icons.location_off_rounded,
            title: 'No fuel stations found',
            subtitle: 'Try a different delivery location.',
            actionLabel: 'Refresh',
            onAction: provider.fetchStations,
          ),
          FuelScreenState.ready => ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.stations.length,
            itemBuilder: (_, i) {
              final station = provider.stations[i];
              return FuelStationCard(
                station: station,
                isSelected: provider.selectedStation == station,
                onTap: () => provider.selectStation(station),
              );
            },
          ),
        },
      ],
    );
  }

  // ── Step: Review (stateless — reads provider only) ───────────────────

  Widget _buildReviewStep(BuildContext context, FuelProvider provider) {
    final theme = Theme.of(context);
    final fuelType = provider.selectedFuelType;
    final estimate = provider.priceEstimate;
    final vehicle = provider.selectedVehicle;
    final station = provider.selectedStation;

    if (fuelType == null ||
        estimate == null ||
        vehicle == null ||
        station == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Review your order details before placing',
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.textTertiary,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: context.border, width: 1),
          ),
          child: Column(
            children: [
              _reviewItem(
                context,
                Icons.local_gas_station_rounded,
                'Fuel',
                '${fuelType.name} • ${provider.quantity.toInt()} L',
              ),
              _reviewItem(
                context,
                Icons.directions_car_rounded,
                'Vehicle',
                vehicle.summary,
              ),
              _reviewItem(
                context,
                Icons.location_on_rounded,
                'Delivery',
                provider.deliveryLocation?.address ?? '',
              ),
              _reviewItem(
                context,
                Icons.local_shipping_rounded,
                'Station',
                station.name,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PriceBreakdown(estimate: estimate),
      ],
    );
  }

  Widget _reviewItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 13, color: context.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context, FuelProvider provider) {
    final theme = Theme.of(context);
    final isLast = _currentStep == _stepLabels.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    provider.isPlacingOrder
                        ? null
                        : (isLast ? _placeOrder : _nextStep),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    provider.isPlacingOrder
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                        : Text(
                          isLast ? 'Place Order' : 'Continue',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step: Vehicle ──────────────────────────────────────────────────────
//
// Holds ONLY the manual-entry form's editing surfaces (toggle, type picker,
// name/number controllers). Selected vehicle data lives in FuelProvider; this
// widget writes through provider.selectVehicle and never caches the result.

class _VehicleStep extends StatefulWidget {
  const _VehicleStep({required this.provider});

  final FuelProvider provider;

  @override
  State<_VehicleStep> createState() => _VehicleStepState();
}

class _VehicleStepState extends State<_VehicleStep> {
  bool _showManualVehicle = false;
  VehicleType _manualVehicleType = VehicleType.car;
  final _vehicleNameController = TextEditingController();
  final _vehicleNumberController = TextEditingController();

  FuelProvider get _provider => widget.provider;

  @override
  void dispose() {
    _vehicleNameController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = _provider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose a saved vehicle or add one',
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.textTertiary,
          ),
        ),
        const SizedBox(height: 20),
        if (provider.savedVehicles.isNotEmpty) ...[
          Text(
            'Saved Vehicles',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < provider.savedVehicles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  FuelVehicleCard(
                    vehicle: provider.savedVehicles[i],
                    isSelected:
                        provider.selectedVehicle == provider.savedVehicles[i],
                    onTap: () {
                      provider.selectVehicle(provider.savedVehicles[i]);
                      setState(() => _showManualVehicle = false);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    () => setState(
                      () => _showManualVehicle = !_showManualVehicle,
                    ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: Text(
                  _showManualVehicle
                      ? 'Use Saved Vehicle'
                      : 'Add Another Vehicle',
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_showManualVehicle) ...[
          const SizedBox(height: 16),
          _manualVehicleFields(context),
        ],
      ],
    );
  }

  Widget _manualVehicleFields(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Type',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children:
              VehicleType.values.map((type) {
                final isSelected = _manualVehicleType == type;
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: type.label,
                  child: GestureDetector(
                    onTap: () => setState(() => _manualVehicleType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.brandOrange : context.cardBg,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.brandOrange
                                  : context.border,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type.icon,
                            size: 16,
                            color:
                                isSelected
                                    ? Colors.white
                                    : context.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _vehicleNameController,
          decoration: const InputDecoration(
            labelText: 'Vehicle Name',
            hintText: 'e.g. My Honda City',
            prefixIcon: Icon(Icons.directions_car_rounded),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _vehicleNumberController,
          onChanged: (_) => _applyManualVehicle(),
          decoration: const InputDecoration(
            labelText: 'Vehicle Number',
            hintText: 'e.g. KA-01-AB-1234',
            prefixIcon: Icon(Icons.confirmation_number_rounded),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 8),
        if (_vehicleNumberController.text.trim().length >= 3)
          FilledButton.tonalIcon(
            onPressed: _applyManualVehicle,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Use This Vehicle'),
          ),
      ],
    );
  }

  void _applyManualVehicle() {
    final name = _vehicleNameController.text.trim();
    final number = _vehicleNumberController.text.trim().toUpperCase();
    if (name.isEmpty || number.isEmpty) return;
    _provider.selectVehicle(
      FuelVehicle(
        id: 'manual',
        type: _manualVehicleType,
        name: name,
        number: number,
      ),
    );
  }
}

// ── Step: Location ─────────────────────────────────────────────────────
//
// Holds ONLY the address/pincode text-edit mirrors and the address focus node.
// The address, pincode, delivery model, detection status and banner all live
// in FuelProvider; the controllers are synced FROM the provider whenever it
// changes (so a GPS result fills the fields), and every keystroke writes back
// through provider.setDeliveryAddress / setDeliveryPincode.

class _LocationStep extends StatefulWidget {
  const _LocationStep({required this.provider});

  final FuelProvider provider;

  @override
  State<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<_LocationStep> {
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _addressFocusNode = FocusNode();

  FuelProvider get _provider => widget.provider;

  @override
  void initState() {
    super.initState();
    _addressController.text = _provider.deliveryAddress;
    _pincodeController.text = _provider.deliveryPincode;
  }

  @override
  void didUpdateWidget(covariant _LocationStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The provider is the source of truth. Reconcile the editing mirrors only
    // when the provider changed under us (e.g. GPS detection filled them).
    if (_provider.deliveryAddress != _addressController.text) {
      _addressController.text = _provider.deliveryAddress;
    }
    if (_provider.deliveryPincode != _pincodeController.text) {
      _pincodeController.text = _provider.deliveryPincode;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _pincodeController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  void _enterManually() {
    _provider.enterManualLocation();
    _addressFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = _provider;
    final showDetected = provider.deliveryLocation != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Location',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Where should we deliver the fuel?',
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.textTertiary,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _addressController,
          focusNode: _addressFocusNode,
          enabled: provider.locationStatus != LocationBannerState.loading,
          minLines: 2,
          maxLines: 3,
          onChanged: provider.setDeliveryAddress,
          decoration: const InputDecoration(
            labelText: 'Delivery Address',
            hintText: 'House no, street, area, city',
            prefixIcon: Icon(Icons.location_on_outlined, size: 20),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pincodeController,
          enabled: provider.locationStatus != LocationBannerState.loading,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: provider.setDeliveryPincode,
          decoration: const InputDecoration(
            labelText: 'Pincode',
            counterText: '',
            prefixIcon: Icon(Icons.markunread_mailbox_outlined, size: 20),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        LocationStatusBanner(
          state: provider.locationStatus,
          isDetecting: provider.isDetectingLocation,
          onDetect: provider.detectDeliveryLocation,
          onEnterManually: _enterManually,
        ),
        const SizedBox(height: 16),
        if (showDetected)
          DeliveryLocationCard(
            location: provider.deliveryLocation!,
            isCompact: true,
            onTap: () {
              if (!provider.isDetectingLocation) {
                provider.detectDeliveryLocation();
              }
            },
          ),
      ],
    );
  }
}
