import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../widgets/pulsing_marker.dart';
import '../widgets/fuel_provider_card.dart';
import '../widgets/fuel_quantity_selector.dart';
import '../widgets/price_breakdown_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_helpers.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';

class FuelSelectionPage extends StatefulWidget {
  const FuelSelectionPage({super.key});

  @override
  State<FuelSelectionPage> createState() => _FuelSelectionPageState();
}

class _FuelSelectionPageState extends State<FuelSelectionPage>
    with SingleTickerProviderStateMixin {
  // ── Animation ──────────────────────────────────────────────────────
  late final AnimationController _pulseController;

  // ── Fuel data ──────────────────────────────────────────────────────
  String? _selectedFuelType;
  String _selectedBrand = '';
  String? _selectedFuelQuality;
  final List<Map<String, dynamic>> _fuelTypes = [
    {"name": "Petrol", "icon": "⛽", "color": Colors.blue},
    {"name": "Diesel", "icon": "🛢️", "color": Colors.green},
    {"name": "CNG", "icon": "🔵", "color": Colors.teal},
    {"name": "EV Charging", "icon": "⚡", "color": Colors.purple},
  ];
  final List<Map<String, dynamic>> _fuelQualities = [
    {"name": "Regular", "octane": "87"},
    {"name": "Premium", "octane": "91"},
    {"name": "Extra Premium", "octane": "95"},
  ];

  // ── Brands ─────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _brands = [
    {"name": "Indian Oil", "color": const Color(0xFF003DA5)},
    {"name": "Hindustan Petroleum", "color": const Color(0xFFD71921)},
    {"name": "Bharat Petroleum", "color": const Color(0xFFF7941D)},
    {"name": "Reliance Petroleum", "color": const Color(0xFF00529B)},
    {"name": "Shell", "color": const Color(0xFFED1C24)},
    {"name": "Nayara Energy", "color": const Color(0xFF00A651)},
  ];

  // ── Map & location ────────────────────────────────────────────────
  final MapController _mapController = MapController();
  _FuelLocationStatus _fuelLocationStatus = _FuelLocationStatus.loading;
  LatLng? _selectedLocation;
  bool _showFuelPanel = false;
  bool _isFetchingAddress = false;
  String _currentAddress = '';
  LatLng? _currentLatLng;
  Marker? _currentLocationMarker;
  List<Marker> _mapMarkers = [];
  List<dynamic> _nearbyPetrolPumps = [];
  bool _showPumpsList = false;
  bool _showPetrolSelection = false;
  bool _showBrandSelection = false;
  bool _showFuelQualitySelection = false;
  bool _showQuantitySelection = false;
  double _currentLitres = 5;
  double _currentRupees = 0;
  String _estimatedArrival = '';

  // ── Lifecycle ──────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Location helpers ───────────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    setState(() => _fuelLocationStatus = _FuelLocationStatus.loading);

    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _fuelLocationStatus = _FuelLocationStatus.gpsDisabled);
        return;
      }

      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.denied || permission == geo.LocationPermission.deniedForever) {
        if (mounted) setState(() => _fuelLocationStatus = _FuelLocationStatus.denied);
        return;
      }

      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(const Duration(seconds: 12));
      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
        _selectedLocation = _currentLatLng;
        _currentLocationMarker = Marker(
          point: _currentLatLng!,
          width: 40,
          height: 40,
          child: PulsingMarker(
            controller: _pulseController,
            type: MarkerType.user,
            label: 'YOU',
          ),
        );
        _mapMarkers = [
          if (_currentLocationMarker != null) _currentLocationMarker!,
        ];
        _fuelLocationStatus = _FuelLocationStatus.ready;
      });
      await _getAddressFromLatLng(_currentLatLng!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(_currentLatLng!, 14);
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) setState(() => _fuelLocationStatus = _FuelLocationStatus.unavailable);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    setState(() => _isFetchingAddress = true);
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}',
        ),
      );
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final address = data['display_name'] ?? '${location.latitude}, ${location.longitude}';
        setState(() {
          _currentAddress = address;
          _isFetchingAddress = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _currentAddress = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
            _isFetchingAddress = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      if (mounted) {
        setState(() {
          _currentAddress = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
          _isFetchingAddress = false;
        });
      }
    }
  }

  Future<void> _fetchNearbyPetrolPumps() async {
    if (_currentLatLng == null) return;
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2:8000/api/v1/map/nearby-pumps?lat=${_currentLatLng!.latitude}&lon=${_currentLatLng!.longitude}&radius=5000',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _nearbyPetrolPumps = data['nearby_pumps'] ?? []);
      } else {
        debugPrint('Failed to load pumps: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching pumps: $e');
    }
  }

  // ── Map interactions ──────────────────────────────────────────────
  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _addPumpMarkers(location);
    _fetchNearbyPetrolPumps();
  }

  void _addPumpMarkers(LatLng location) async {
    final newMarkers = <Marker>[
      Marker(
        point: location,
        width: 40,
        height: 40,
        child: PulsingMarker(
          controller: _pulseController,
          type: MarkerType.user,
          label: 'YOU',
        ),
      ),
    ];

    final pumpsToUse = _nearbyPetrolPumps.isNotEmpty ? _nearbyPetrolPumps : _dummyPumps;

    for (int i = 0; i < pumpsToUse.length; i++) {
      final pump = pumpsToUse[i];
      final pumpLocation = LatLng(
        double.tryParse(pump['latitude']?.toString() ?? '') ?? 0,
        double.tryParse(pump['longitude']?.toString() ?? '') ?? 0,
      );

      if (pumpLocation.latitude != 0 && pumpLocation.longitude != 0) {
        final distance = _calculateDistance(location, pumpLocation);
        newMarkers.add(
          Marker(
            point: pumpLocation,
            width: 40,
            height: 40,
            child: PulsingMarker(
              controller: _pulseController,
              type: MarkerType.fuel,
              label: '${distance.toStringAsFixed(1)}km',
            ),
          ),
        );
      }
    }

    setState(() => _mapMarkers = newMarkers);
  }

  void _animateCameraToLocation(LatLng location) {
    _mapController.move(location, 14);
    _addPumpMarkers(location);
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((end.latitude - start.latitude) * p) / 2 +
        cos(start.latitude * p) * cos(end.latitude * p) * (1 - cos((end.longitude - start.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  List<Map<String, dynamic>> get _dummyPumps => [
    {"id": "1", "name": "Indian Oil - ${_currentAddress.isNotEmpty ? _currentAddress : 'Nearby'}", "latitude": _selectedLocation?.latitude ?? 0, "longitude": _selectedLocation?.longitude ?? 0, "distance": "1.5 km", "status": "Open", "petrol_price": "98.20", "diesel_price": "89.50"},
    {"id": "2", "name": "HP Petrol Pump", "latitude": (_selectedLocation?.latitude ?? 0) + 0.005, "longitude": (_selectedLocation?.longitude ?? 0) + 0.003, "distance": "2.0 km", "status": "Open", "petrol_price": "98.00", "diesel_price": "89.30"},
    {"id": "3", "name": "Bharat Petroleum", "latitude": (_selectedLocation?.latitude ?? 0) - 0.004, "longitude": (_selectedLocation?.longitude ?? 0) - 0.002, "distance": "2.5 km", "status": "Closed", "petrol_price": "98.50", "diesel_price": "89.80"},
  ];

  // ── Place order ────────────────────────────────────────────────────
  Future<void> _placeFuelOrder() async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Placing your fuel order...'),
          backgroundColor: AppColors.brandBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      final orderId = DateTime.now().millisecondsSinceEpoch % 100000;
      final estimatedArrival = '5 mins';

      if (!mounted) return;
      setState(() => _estimatedArrival = estimatedArrival);
      _showOrderConfirmationDialog(orderId, estimatedArrival);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to place order. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _startOrderTracking(int orderId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order #$orderId is being tracked. You will be notified on updates.'),
        backgroundColor: AppColors.brandBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── UI Builders ────────────────────────────────────────────────────
  Widget _buildGoogleMap() {
    return Positioned.fill(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLatLng ?? const LatLng(12.9716, 77.5946),
          initialZoom: 12,
          onTap: (tapPosition, point) => _onMapTap(point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mecha_connect',
          ),
          MarkerLayer(markers: _mapMarkers),
        ],
      ),
    );
  }

  Widget _buildUserPulseOverlay() {
    if (_currentLatLng == null) return const SizedBox.shrink();
    return Positioned(
      left: MediaQuery.of(context).size.width / 2 - 22,
      top: MediaQuery.of(context).size.height * 0.35,
      child: PulsingMarker(
        controller: _pulseController,
        type: MarkerType.user,
        label: 'YOU',
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: _showFuelPanel ? 240 : 24,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: !_showFuelPanel
            ? GestureDetector(
                key: const ValueKey('search_card'),
                onTap: () => setState(() => _showFuelPanel = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.brandOrangeLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_gas_station_rounded,
                          color: AppColors.brandOrange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedFuelType ?? 'Find Fuel Stations',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Space Grotesk',
                                color: _selectedFuelType != null
                                    ? context.textPrimary
                                    : context.textSecondary,
                              ),
                            ),
                            if (_selectedFuelType != null && _selectedBrand.isNotEmpty)
                              Text(
                                _selectedBrand,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textTertiary,
                                ),
                              ),
                            if (_selectedFuelType == null)
                              Text(
                                'Tap to search nearby pumps',
                                style: TextStyle(fontSize: 12, color: context.textTertiary),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.brandOrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildFuelPanel() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      left: 0,
      right: 0,
      bottom: _showFuelPanel ? 0 : -400,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 400,
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 25,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildPanelHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAddressSection(),
                      const SizedBox(height: 16),
                      _buildCurrentLocationCard(),
                      const SizedBox(height: 16),
                      _buildFindStationsButton(),
                      const SizedBox(height: 16),
                      if (_showBrandSelection) _buildBrandSection(),
                      if (_showFuelQualitySelection) _buildFuelQualitySection(),
                      if (_showQuantitySelection) _buildQuantitySection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Column(
      children: [
        Center(
          child: Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: context.textTertiary,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF15A22), Color(0xFFFF7043)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_gas_station_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Select Fuel",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Space Grotesk',
                    color: context.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _showFuelPanel = false;
                  _showBrandSelection = false;
                  _showFuelQualitySelection = false;
                  _showQuantitySelection = false;
                  _selectedFuelType = null;
                  _selectedBrand = '';
                  _selectedFuelQuality = null;
                }),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.bgTertiary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.close, color: context.textSecondary, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Location',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.bgTertiary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandOrangeLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.brandOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentAddress.isNotEmpty)
                      Text(
                        _currentAddress,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (_isFetchingAddress)
                      Text(
                        'Fetching address...',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Text(
                        'Tap map to set location',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textTertiary,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      'Exact location for delivery',
                      style: TextStyle(fontSize: 11, color: context.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentLocationCard() {
    if (_currentAddress.isEmpty && !_isFetchingAddress) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandOrangeLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandOrange.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location_rounded, color: AppColors.brandOrange, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Current Location',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _currentAddress,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          if (_currentLatLng != null) ...[
            const SizedBox(height: 4),
            Text(
              'Lat: ${_currentLatLng!.latitude.toStringAsFixed(4)}, Lon: ${_currentLatLng!.longitude.toStringAsFixed(4)}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textTertiary,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFindStationsButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _currentLatLng != null
            ? () {
                _fetchNearbyPetrolPumps();
                setState(() => _showPumpsList = true);
                _animateCameraToLocation(_currentLatLng!);
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _currentLatLng != null
              ? AppColors.brandOrange
              : AppColors.grey300,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Find Stations',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Space Grotesk',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.brandBlueLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.business_rounded, size: 14, color: AppColors.brandBlue),
            ),
            const SizedBox(width: 10),
            Text(
              "Select Brand",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'Space Grotesk',
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _brands.map((brand) {
            final isSelected = _selectedBrand == brand['name'];
            return GestureDetector(
              onTap: () => setState(() => _selectedBrand = brand['name']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? brand['color'].withValues(alpha: 0.1) : context.bgTertiary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? brand['color'] : context.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  brand['name'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? brand['color'] : context.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFuelQualitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.brandOrangeLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star_rounded, size: 14, color: AppColors.brandOrange),
            ),
            const SizedBox(width: 10),
            Text(
              "Fuel Quality",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'Space Grotesk',
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: _fuelQualities.map((quality) {
            final isSelected = _selectedFuelQuality == quality['name'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFuelQuality = quality['name']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brandOrangeLight : context.bgTertiary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.brandOrange : context.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          quality['name']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Space Grotesk',
                            color: isSelected ? AppColors.brandOrange : context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${quality['octane']} Octane",
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? AppColors.brandOrange : context.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.water_drop_rounded, size: 14, color: AppColors.success),
            ),
            const SizedBox(width: 10),
            Text(
              "Fuel Quantity",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'Space Grotesk',
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FuelQuantitySelector(
          fuelType: _selectedFuelType ?? 'Petrol',
          litres: _currentLitres,
          rupees: _currentRupees,
          pricePerLitre: 98.20,
          onLitresChanged: (v) => setState(() => _currentLitres = v),
          onRupeesChanged: (v) => setState(() => _currentRupees = v),
        ),
        const SizedBox(height: 16),
        PriceBreakdownCard(
          fuelType: _selectedFuelQuality != null
              ? '$_selectedFuelType $_selectedFuelQuality'
              : _selectedFuelType ?? 'Petrol',
          quantity: _currentLitres,
          pricePerLitre: 98.20,
          deliveryFee: 29,
          eta: _estimatedArrival.isNotEmpty ? _estimatedArrival : null,
        ),
        const SizedBox(height: 20),
        _buildPlaceOrderButton(),
      ],
    );
  }

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _placeFuelOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text(
          "Place Order",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Space Grotesk',
          ),
        ),
      ),
    );
  }

  Widget _buildFuelTypeSelection() {
    if (!_showPetrolSelection) return const SizedBox.shrink();
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF15A22), Color(0xFFFF7043)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_gas_station_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Select Fuel Type",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Space Grotesk',
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: _fuelTypes.map((fuel) {
                final isSelected = _selectedFuelType == fuel['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedFuelType = fuel['name']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (fuel['color'] as Color).withValues(alpha: 0.15)
                          : context.bgTertiary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? (fuel['color'] as Color) : context.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(fuel['icon'] as String, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 8),
                        Text(
                          fuel['name'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Space Grotesk',
                            color: isSelected ? fuel['color'] as Color : context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Tap to select",
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? fuel['color'] as Color : context.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyPumpsList() {
    if (!_showPumpsList) return const SizedBox.shrink();
    final pumps = _nearbyPetrolPumps.isNotEmpty ? _nearbyPetrolPumps : _dummyPumps;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_gas_station, color: AppColors.success, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  "Nearby Stations",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Space Grotesk',
                    color: context.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  "${pumps.length} Found",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...pumps.map((pump) {
              final distance = _currentLatLng != null
                  ? _calculateDistance(
                      _currentLatLng!,
                      LatLng(
                        double.tryParse(pump['latitude']?.toString() ?? '') ?? 0,
                        double.tryParse(pump['longitude']?.toString() ?? '') ?? 0,
                      ),
                    )
                  : null;
              return FuelProviderCard(
                name: pump['name'] ?? 'Fuel Station',
                brand: _selectedBrand.isNotEmpty ? _selectedBrand : 'Indian Oil',
                distance: distance != null ? '${distance.toStringAsFixed(1)} km' : null,
                eta: pump['status'] == 'Open' ? '5-10 min' : null,
                isVerified: true,
                isAvailable: pump['status'] != 'Closed',
                onCall: () {
                  final phone = pump['phone'];
                  if (phone != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling $phone...'),
                        backgroundColor: AppColors.brandOrange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
                onTap: () {
                  setState(() {
                    _showFuelPanel = true;
                    _selectedBrand = pump['name'] ?? '';
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showOrderConfirmationDialog(int orderId, String estimatedArrival) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: context.cardBg,
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
            const SizedBox(width: 10),
            Text(
              'Order Placed',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'Space Grotesk',
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #$orderId has been placed successfully.',
              style: TextStyle(color: context.textSecondary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated arrival: $estimatedArrival',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startOrderTracking(orderId);
            },
            child: const Text(
              'Track Order',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.brandOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: _fuelLocationStatus != _FuelLocationStatus.ready
          ? _buildFuelLocationState()
          : Stack(
        children: [
          _buildGoogleMap(),
          _buildUserPulseOverlay(),
          _buildFloatingControls(),
          _buildFuelTypeSelection(),
          _buildNearbyPumpsList(),
          _buildFuelPanel(),
        ],
      ),
    );
  }

  Widget _buildFuelLocationState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFuelStateIcon(),
            const SizedBox(height: 20),
            Text(_fuelStateTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.textPrimary)),
            const SizedBox(height: 8),
            Text(_fuelStateSubtitle, style: TextStyle(fontSize: 13, color: context.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            _buildFuelStateAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelStateIcon() {
    switch (_fuelLocationStatus) {
      case _FuelLocationStatus.loading:
        return const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.brandOrange));
      case _FuelLocationStatus.denied:
        return Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.location_off_rounded, size: 28, color: AppColors.error));
      case _FuelLocationStatus.gpsDisabled:
        return Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.signal_wifi_off_rounded, size: 28, color: AppColors.warning));
      case _FuelLocationStatus.unavailable:
        return Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.search_off_rounded, size: 28, color: AppColors.info));
      case _FuelLocationStatus.ready:
        return const SizedBox.shrink();
    }
  }

  String get _fuelStateTitle {
    switch (_fuelLocationStatus) {
      case _FuelLocationStatus.loading: return 'Finding your location';
      case _FuelLocationStatus.denied: return 'Location Permission Denied';
      case _FuelLocationStatus.gpsDisabled: return 'GPS is Disabled';
      case _FuelLocationStatus.unavailable: return 'Unable to Determine Location';
      case _FuelLocationStatus.ready: return '';
    }
  }

  String get _fuelStateSubtitle {
    switch (_fuelLocationStatus) {
      case _FuelLocationStatus.loading: return 'Please wait while we find nearby fuel stations';
      case _FuelLocationStatus.denied: return 'Enable location access in Settings to find fuel stations near you';
      case _FuelLocationStatus.gpsDisabled: return 'Turn on GPS to discover fuel stations in your area';
      case _FuelLocationStatus.unavailable: return 'We couldn\'t determine your location. Please try again.';
      case _FuelLocationStatus.ready: return '';
    }
  }

  Widget _buildFuelStateAction() {
    switch (_fuelLocationStatus) {
      case _FuelLocationStatus.loading:
        return const SizedBox.shrink();
      case _FuelLocationStatus.denied:
        return Column(
          children: [
            _fuelActionButton('Open Settings', Icons.settings_rounded, () => openAppSettings()),
            const SizedBox(height: 8),
            _fuelActionButton('Retry', Icons.refresh_rounded, () => _getCurrentLocation(), outlined: true),
          ],
        );
      case _FuelLocationStatus.gpsDisabled:
        return Column(
          children: [
            _fuelActionButton('Enable GPS', Icons.settings_remote_rounded, () => geo.Geolocator.openLocationSettings()),
            const SizedBox(height: 8),
            _fuelActionButton('Retry', Icons.refresh_rounded, () => _getCurrentLocation(), outlined: true),
          ],
        );
      case _FuelLocationStatus.unavailable:
        return Column(
          children: [
            _fuelActionButton('Retry', Icons.refresh_rounded, () => _getCurrentLocation()),
            const SizedBox(height: 8),
            _fuelActionButton('Set Manually', Icons.edit_location_alt_rounded, () {
              setState(() {
                _currentLatLng = const LatLng(12.9716, 77.5946);
                _selectedLocation = _currentLatLng;
                _currentAddress = 'Bengaluru, Karnataka';
                _fuelLocationStatus = _FuelLocationStatus.ready;
              });
            }, outlined: true),
          ],
        );
      case _FuelLocationStatus.ready:
        return const SizedBox.shrink();
    }
  }

  Widget _fuelActionButton(String label, IconData icon, VoidCallback onTap, {bool outlined = false}) {
    return SizedBox(
      width: 220,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: outlined ? BorderSide(color: context.border) : BorderSide.none,
          backgroundColor: outlined ? Colors.transparent : AppColors.brandOrange,
          foregroundColor: outlined ? context.textPrimary : Colors.white,
        ),
      ),
    );
  }
}

enum _FuelLocationStatus { loading, denied, gpsDisabled, unavailable, ready }
