import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mecha_connect/features/fuel_delivery/constants/fuel_constants.dart';
import 'package:mecha_connect/features/fuel_delivery/models/models.dart';
import 'package:mecha_connect/features/fuel_delivery/providers/fuel_provider.dart';
import 'package:mecha_connect/features/fuel_delivery/repositories/fuel_repository.dart';
import 'package:mecha_connect/features/fuel_delivery/screens/fuel_booking_screen.dart';
import 'package:mecha_connect/features/fuel_delivery/screens/fuel_home_screen.dart';
import 'package:mecha_connect/features/fuel_delivery/services/fuel_service.dart';
import 'package:mecha_connect/features/fuel_delivery/widgets/delivery_location_card.dart';
import 'package:mecha_connect/features/fuel_delivery/widgets/fuel_station_card.dart';
import 'package:mecha_connect/features/fuel_delivery/widgets/fuel_vehicle_card.dart';
import 'package:mecha_connect/features/fuel_delivery/widgets/quantity_selector.dart';
import 'package:mecha_connect/features/fuel_delivery/widgets/recent_order_card.dart';
import 'package:mecha_connect/features/fuel_delivery/widgets/tracking_timeline.dart';
import 'package:mecha_connect/services/geocoding_service.dart';
import 'package:mecha_connect/services/location_provider.dart';
import 'package:mecha_connect/widgets/app_loading.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _vehicle = FuelVehicle(
  id: 'v1',
  type: VehicleType.car,
  name: 'Honda City',
  number: 'KA-01-AB-1234',
);
const _location = DeliveryLocation(
  latitude: 12.9716,
  longitude: 77.5946,
  address: 'MG Road, Bengaluru',
  label: 'Home',
);

class _FakeLocationProvider extends LocationProvider {
  _FakeLocationProvider({this.details});

  final GeocodingResult? details;

  @override
  bool get hasLocation => true;

  @override
  LatLng? get currentLatLng => const LatLng(12.9716, 77.5946);

  @override
  GeocodingResult? get currentAddressDetails => details;

  @override
  String get currentAddress => details?.fullAddress ?? '';

  @override
  LocationPermissionState get permissionState => LocationPermissionState.granted;

  @override
  Future<void> checkAndRequestPermission() async {}

  @override
  Future<bool> getCurrentLocation() async => true;
}

/// Permission request itself fails (throws) once the wizard triggers a second
/// call — the constructor's boot [_initLocation] consumes the first one. The
/// detection pipeline must surface the throw as the error state, never hang on
/// "loading".
class _ThrowingLocationProvider extends LocationProvider {
  int _calls = 0;

  @override
  bool get hasLocation => false;

  @override
  LatLng? get currentLatLng => null;

  @override
  GeocodingResult? get currentAddressDetails => null;

  @override
  String get currentAddress => '';

  @override
  LocationPermissionState get permissionState => LocationPermissionState.denied;

  @override
  Future<void> checkAndRequestPermission() async {
    _calls++;
    if (_calls > 1) throw StateError('permission denied');
  }

  @override
  Future<bool> getCurrentLocation() async => false;
}

class _LoadingLocationProvider extends LocationProvider {
  final _never = Completer<bool>();

  @override
  bool get hasLocation => false;

  @override
  LatLng? get currentLatLng => null;

  @override
  GeocodingResult? get currentAddressDetails => null;

  @override
  String get currentAddress => '';

  @override
  LocationPermissionState get permissionState => LocationPermissionState.granted;

  @override
  Future<void> checkAndRequestPermission() async {}

  @override
  Future<bool> getCurrentLocation() => _never.future;
}

class _DeniedLocationProvider extends LocationProvider {
  @override
  bool get hasLocation => false;

  @override
  LatLng? get currentLatLng => null;

  @override
  GeocodingResult? get currentAddressDetails => null;

  @override
  String get currentAddress => '';

  @override
  LocationPermissionState get permissionState => LocationPermissionState.denied;

  @override
  Future<void> checkAndRequestPermission() async {}

  @override
  Future<bool> getCurrentLocation() async => false;
}

class _FailingLocationProvider extends LocationProvider {
  @override
  bool get hasLocation => false;

  @override
  LatLng? get currentLatLng => null;

  @override
  GeocodingResult? get currentAddressDetails => null;

  @override
  String get currentAddress => '';

  @override
  LocationPermissionState get permissionState => LocationPermissionState.granted;

  @override
  Future<void> checkAndRequestPermission() async {}

  @override
  Future<bool> getCurrentLocation() async => false;
}

/// Mimics the real async slow path: permission, GPS fix, then geocode — each
/// an awaited hop so detection crosses multiple frames.
class _SlowResolvingLocationProvider extends LocationProvider {
  bool _resolved = false;
  LocationPermissionState _permission = LocationPermissionState.initial;

  @override
  bool get hasLocation => _resolved;

  @override
  LatLng? get currentLatLng => _resolved ? const LatLng(12.9716, 77.5946) : null;

  @override
  GeocodingResult? get currentAddressDetails => _resolved ? _details : null;

  @override
  String get currentAddress => _resolved ? 'MG Road, Bengaluru' : '';

  @override
  LocationPermissionState get permissionState => _permission;

  @override
  Future<void> checkAndRequestPermission() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _permission = LocationPermissionState.granted;
    notifyListeners();
  }

  @override
  Future<bool> getCurrentLocation() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _resolved = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    notifyListeners();
    return true;
  }
}

/// GPS fix reports success but reverse geocoding produced no address — the
/// classic "success banner next to empty fields" failure mode.
class _NoAddressLocationProvider extends LocationProvider {
  LocationPermissionState _permission = LocationPermissionState.initial;

  @override
  bool get hasLocation => false;

  @override
  LatLng? get currentLatLng => null;

  @override
  GeocodingResult? get currentAddressDetails => null;

  @override
  String get currentAddress => '';

  @override
  LocationPermissionState get permissionState => _permission;

  @override
  Future<void> checkAndRequestPermission() async {
    _permission = LocationPermissionState.granted;
    notifyListeners();
  }

  @override
  Future<bool> getCurrentLocation() async => true;
}

const _details = GeocodingResult(
  street: 'MG Road',
  locality: 'Indiranagar',
  city: 'Bengaluru',
  state: 'Karnataka',
  pincode: '560001',
);

Widget _wrap(
  Widget child, {
  FuelProvider? fuel,
  LocationProvider? location,
  double? textScale,
}) {
  final locationProvider = location ?? _FakeLocationProvider();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<FuelProvider>(
        create: (_) => fuel ?? FuelProvider(locationProvider: locationProvider),
      ),
      ChangeNotifierProvider<LocationProvider>(create: (_) => locationProvider),
    ],
    child: MaterialApp(
      builder: textScale == null
          ? null
          : (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
      home: child,
    ),
  );
}

// Same as [_wrap] but provides the notifiers via `.value` so they are NOT
// disposed when the tree is torn down mid-test (needed when re-pumping trees
// that share one provider instance).
Widget _wrapShared(
  Widget child, {
  required FuelProvider fuel,
  required LocationProvider location,
  double? textScale,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<FuelProvider>.value(value: fuel),
      ChangeNotifierProvider<LocationProvider>.value(value: location),
    ],
    child: MaterialApp(
      builder: textScale == null
          ? null
          : (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
      home: child,
    ),
  );
}

Future<void> _preload(FuelProvider fuel, WidgetTester tester) async {
  fuel.loadHome();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump(const Duration(milliseconds: 800));
}

Future<FuelOrder> _seedOrder(FuelProvider provider) async {
  await provider.loadHome();
  provider.selectFuelType(FuelType.petrol);
  provider.setQuantity(5);
  provider.selectVehicle(provider.savedVehicles.first);
  provider.setDeliveryLocation(_location);
  await provider.fetchStations();
  final station = provider.stations.firstWhere((s) => s.isSelectable);
  provider.selectStation(station);
  await provider.placeOrder();
  return provider.activeOrder!;
}

// ── Unit: Service / Enums ──────────────────────────────────────────────

void main() {
  group('FuelService', () {
    test('orderable fuel types exclude coming-soon options', () {
      expect(
        FuelType.orderable.map((t) => t.name).toList(),
        ['Petrol', 'Diesel', 'Premium Petrol'],
      );
      expect(FuelType.electric.comingSoon, isTrue);
      expect(FuelType.cng.comingSoon, isTrue);
    });

    test('calculatePrice uses station rate and eta', () {
      final estimate = FuelService().calculatePrice(
        FuelType.petrol,
        5,
        pricePerLitre: 100.0,
        etaMinutes: 12,
      );
      expect(estimate.fuelCost, closeTo(500, 0.01));
      expect(estimate.etaMinutes, 12);
      expect(estimate.grandTotal, closeTo((500 + 29 + 5) * 1.02, 0.01));
    });

    test('quantity validation clamps to min/max', () {
      expect(FuelService().isValidQuantity(0), isFalse);
      expect(FuelService().isValidQuantity(21), isFalse);
      expect(FuelService().isValidQuantity(10), isTrue);
    });
  });

  group('OrderStatus', () {
    test('labels match the 7 required tracking states', () {
      expect(
        OrderStatus.values.map((s) => s.label).toList(),
        [
          'Requested',
          'Accepted',
          'Fuel Packed',
          'Delivery Partner Assigned',
          'En Route',
          'Arrived',
          'Delivered',
          'Cancelled',
        ],
      );
    });

    test('delivered and cancelled are terminal', () {
      expect(OrderStatus.delivered.isTerminal, isTrue);
      expect(OrderStatus.cancelled.isTerminal, isTrue);
      expect(OrderStatus.enRoute.isTerminal, isFalse);
    });
  });

  // ── Unit: Repository ──────────────────────────────────────────────────

  group('FuelRepository', () {
    test('seeds 5 order-history entries', () async {
      final repo = FuelRepository();
      final history = await repo.refreshHistory();
      expect(history.length, 5);
      expect(history.first.id, 'FUEL-2026-0009');
      expect(history.first.status, OrderStatus.delivered);
      expect(history.any((o) => o.status == OrderStatus.cancelled), isTrue);
    });

    test('returns fuel stations sorted by distance with varied availability', () async {
      final repo = FuelRepository();
      final stations = await repo.getFuelStations(
        latitude: 12.9716,
        longitude: 77.5946,
      );
      expect(stations.length, 6);
      for (var i = 0; i < stations.length - 1; i++) {
        expect(
          stations[i].distanceKm <= stations[i + 1].distanceKm,
          isTrue,
          reason: 'stations should be sorted nearest first',
        );
      }
      expect(stations.where((s) => !s.isSelectable), isNotEmpty);
    });

    test('createOrder uses station pricing and requested status', () async {
      final repo = FuelRepository();
      final station = (await repo.getFuelStations(
        latitude: 12.9716,
        longitude: 77.5946,
      )).first;
      final order = await repo.createOrder(
        fuelType: FuelType.petrol,
        quantity: 5,
        vehicle: _vehicle,
        location: _location,
        station: station,
      );
      expect(order.status, OrderStatus.requested);
      expect(order.id, startsWith('FUEL-'));
      expect(order.station?.id, station.id);
      expect(order.priceEstimate.fuelCost, closeTo(station.pricePerLitre * 5, 0.01));
      expect(order.priceEstimate.etaMinutes, station.etaMinutes);
    });

    test('advanceStatus walks the full sequence and assigns a partner', () async {
      final repo = FuelRepository();
      final station = (await repo.getFuelStations(
        latitude: 12.9716,
        longitude: 77.5946,
      )).first;
      final order = await repo.createOrder(
        fuelType: FuelType.diesel,
        quantity: 10,
        vehicle: _vehicle,
        location: _location,
        station: station,
      );

      const sequence = [
        OrderStatus.accepted,
        OrderStatus.fuelPacked,
        OrderStatus.partnerAssigned,
        OrderStatus.enRoute,
        OrderStatus.arrived,
        OrderStatus.delivered,
      ];

      FuelOrder? current = order;
      for (final expected in sequence) {
        current = await repo.advanceStatus(order.id);
        expect(current!.status, expected);
        if (expected == OrderStatus.partnerAssigned) {
          expect(current.partner, isNotNull);
        }
      }

      final terminal = await repo.advanceStatus(order.id);
      expect(terminal!.status, OrderStatus.delivered);
    });

    test('completeOrder attaches an invoice', () async {
      final repo = FuelRepository();
      final station = (await repo.getFuelStations(
        latitude: 12.9716,
        longitude: 77.5946,
      )).first;
      final order = await repo.createOrder(
        fuelType: FuelType.petrol,
        quantity: 5,
        vehicle: _vehicle,
        location: _location,
        station: station,
      );
      await repo.advanceStatus(order.id);
      final completed = await repo.completeOrder(order.id);
      expect(completed.status, OrderStatus.delivered);
      expect(completed.invoice, isNotNull);
      expect(completed.invoice!.orderId, order.id);
      expect(completed.invoice!.grandTotal, completed.priceEstimate.grandTotal);
    });

    test('cancelOrder sets cancelled status', () async {
      final repo = FuelRepository();
      final station = (await repo.getFuelStations(
        latitude: 12.9716,
        longitude: 77.5946,
      )).first;
      final order = await repo.createOrder(
        fuelType: FuelType.petrol,
        quantity: 5,
        vehicle: _vehicle,
        location: _location,
        station: station,
      );
      final cancelled = await repo.cancelOrder(order.id);
      expect(cancelled.status, OrderStatus.cancelled);
    });
  });

  // ── Provider ──────────────────────────────────────────────────────────

  group('FuelProvider', () {
    test('loadHome populates fuel types, vehicles and history', () async {
      final provider = FuelProvider(locationProvider: _FakeLocationProvider());
      await provider.loadHome();
      expect(provider.state, FuelScreenState.ready);
      expect(provider.fuelTypes.length, 5);
      expect(provider.savedVehicles.length, 3);
      expect(provider.orderHistory.length, 5);
    });

    test('coming-soon fuel types cannot be selected', () {
      final provider = FuelProvider(locationProvider: _FakeLocationProvider());
      provider.selectFuelType(FuelType.electric);
      expect(provider.selectedFuelType, isNull);
      provider.selectFuelType(FuelType.petrol);
      expect(provider.selectedFuelType, FuelType.petrol);
    });

    test('quantity clamps to configured min/max', () {
      final provider = FuelProvider(locationProvider: _FakeLocationProvider());
      provider.setQuantity(50);
      expect(provider.quantity, FuelConstants.maxLitres);
      provider.setQuantity(0);
      expect(provider.quantity, FuelConstants.minLitres);
    });

    test('price estimate reflects the selected station rate', () async {
      final provider = FuelProvider(locationProvider: _FakeLocationProvider());
      await provider.loadHome();
      provider.selectFuelType(FuelType.diesel);
      provider.setQuantity(10);
      await provider.fetchStations();
      final station = provider.stations.firstWhere((s) => s.isSelectable);
      provider.selectStation(station);
      expect(provider.priceEstimate, isNotNull);
      expect(
        provider.priceEstimate!.fuelCost,
        closeTo(station.pricePerLitre * 10, 0.01),
      );
      expect(provider.priceEstimate!.etaMinutes, station.etaMinutes);
    });

    test('placeOrder is rejected without full selections', () async {
      final provider = FuelProvider(locationProvider: _FakeLocationProvider());
      await provider.loadHome();
      expect(provider.canPlaceOrder, isFalse);
      expect(await provider.placeOrder(), isFalse);
      expect(provider.activeOrder, isNull);
    });

    test('full lifecycle: place, accept, cancel', () async {
      final provider = FuelProvider(locationProvider: _FakeLocationProvider());
      final order = await _seedOrder(provider);
      expect(order.status, OrderStatus.requested);
      expect(provider.orderHistory.length, 6);

      expect(await provider.acceptOrder(), isTrue);
      expect(provider.activeOrder!.status, OrderStatus.accepted);

      final cancelled = await provider.cancelOrder();
      expect(cancelled!.status, OrderStatus.cancelled);
      expect(provider.orderHistory.length, 6);
      expect(provider.orderHistory.first.status, OrderStatus.cancelled);
    });

    test('completeOrder attaches the invoice', () async {
      final provider = FuelProvider(locationProvider: _FakeLocationProvider());
      await _seedOrder(provider);
      await provider.acceptOrder();
      final completed = await provider.completeOrder();
      expect(completed!.status, OrderStatus.delivered);
      expect(completed.invoice, isNotNull);
      expect(provider.orderHistory.first.invoice, isNotNull);
    });
  });

  // ── Widget: Fuel Home ─────────────────────────────────────────────────

  group('FuelHomeScreen', () {
    testWidgets('renders banner, fuel options and recent orders', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final fuel = FuelProvider(locationProvider: _FakeLocationProvider());
      await _preload(fuel, tester);

      await tester.pumpWidget(_wrap(const FuelHomeScreen(), fuel: fuel));

      expect(find.text('Fuel Delivery'), findsWidgets);
      expect(find.text('Order Fuel Now'), findsOneWidget);
      expect(find.text('Coming Soon'), findsNWidgets(2));
      expect(find.byType(RecentOrderCard), findsNWidgets(3));
    });

    testWidgets('auto-loads data on first open and leaves loading', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final fuel = FuelProvider(locationProvider: _FakeLocationProvider());

      await tester.pumpWidget(_wrap(const FuelHomeScreen(), fuel: fuel));

      expect(find.byType(AppLoading), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byType(AppLoading), findsNothing);
      expect(find.text('Coming Soon'), findsNWidgets(2));
      expect(find.byType(RecentOrderCard), findsNWidgets(3));
    });

    testWidgets('renders without overflow on a 320dp screen', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final fuel = FuelProvider(locationProvider: _FakeLocationProvider());
      await _preload(fuel, tester);

      await tester.pumpWidget(_wrap(const FuelHomeScreen(), fuel: fuel));
      await tester.pump();

      expect(find.text('Order Fuel Now'), findsOneWidget);
      expect(find.byType(RecentOrderCard), findsNWidgets(3));
    });
  });

  // ── Widget: Booking Wizard ────────────────────────────────────────────

  group('FuelBookingScreen', () {
    testWidgets('completes the 5-step flow and reaches payment', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final location = _FakeLocationProvider(
        details: const GeocodingResult(
          street: 'MG Road',
          locality: 'Indiranagar',
          city: 'Bengaluru',
          state: 'Karnataka',
          pincode: '560001',
        ),
      );
      final fuel = FuelProvider(locationProvider: location);
      await _preload(fuel, tester);

      await tester.pumpWidget(
        _wrap(const FuelBookingScreen(), fuel: fuel, location: location),
      );

      // Step 1 — Fuel type
      expect(find.text('Select Fuel Type'), findsOneWidget);
      expect(find.text('Petrol'), findsWidgets);
      await tester.tap(find.text('Continue'));
      await tester.pump();

      // Step 2 — Vehicle
      expect(find.text('Vehicle Details'), findsOneWidget);
      await tester.tap(find.text('Honda City'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();

      // Step 3 — Location (auto-detect fills the address)
      expect(find.text('Delivery Location'), findsOneWidget);
      await tester.pump();
      expect(find.text('📍 Current Location Detected'), findsOneWidget);
      expect(find.textContaining('MG Road'), findsWidgets);
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 900));

      // Step 4 — Station
      expect(find.text('Select Fuel Station'), findsOneWidget);
      expect(find.byType(FuelStationCard), findsWidgets);
      final index = fuel.stations.indexWhere((s) => s.isSelectable);
      await tester.tap(find.byType(FuelStationCard).at(index));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();

      // Step 5 — Review → Place Order → Payment
      expect(find.text('Order Summary'), findsOneWidget);
      await tester.tap(find.text('Place Order'));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump();

      expect(find.text('Amount to Pay'), findsOneWidget);
      expect(find.text('Select Payment Method'), findsOneWidget);
    });

    testWidgets('shows the persistent bottom bar on all 5 steps at 320dp', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final location = _FakeLocationProvider(
        details: const GeocodingResult(
          street: 'MG Road',
          locality: 'Indiranagar',
          city: 'Bengaluru',
          state: 'Karnataka',
          pincode: '560001',
        ),
      );
      final fuel = FuelProvider(locationProvider: location);
      await _preload(fuel, tester);

      await tester.pumpWidget(
        _wrap(const FuelBookingScreen(), fuel: fuel, location: location),
      );

      // Step 1 — Fuel: no Back yet, Continue present (persistent bottom bar).
      expect(find.text('Select Fuel Type'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pump();

      // Step 2 — Vehicle.
      expect(find.text('Vehicle Details'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Honda City'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();

      // Step 3 — Location, keyboard open: bottom bar must stay visible.
      expect(find.text('Delivery Location'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pump();
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('📍 Current Location Detected'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 900));

      // Step 4 — Station.
      expect(find.text('Select Fuel Station'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      final index = fuel.stations.indexWhere((s) => s.isSelectable);
      await tester.ensureVisible(find.byType(FuelStationCard).at(index));
      await tester.pump();
      await tester.tap(find.byType(FuelStationCard).at(index));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();

      // Step 5 — Review: Back + Place Order.
      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Place Order'), findsOneWidget);
    });

    testWidgets('location error state fits at 320dp', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final location = _FailingLocationProvider();
      final fuel = FuelProvider(locationProvider: location);
      await _preload(fuel, tester);

      await tester.pumpWidget(
        _wrap(
          const FuelBookingScreen(),
          fuel: fuel,
          location: location,
        ),
      );

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.tap(find.text('Honda City'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Unable to determine your location.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Enter Manually'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('permission request failure shows the error banner, never hangs',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final location = _ThrowingLocationProvider();
      final fuel = FuelProvider(locationProvider: location);
      await _preload(fuel, tester);

      await tester.pumpWidget(_wrapShared(
        const FuelBookingScreen(),
        fuel: fuel,
        location: location,
      ));

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.tap(find.byType(FuelVehicleCard).first);
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Unable to determine your location.'), findsOneWidget);
      expect(find.text('Loading current location...'), findsNothing,
          reason: 'a throwing permission request must exit the loading state');
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets(
        'location status area keeps a constant height and pins Continue across all 5 states',
        (tester) async {
      for (final width in [320.0, 360.0, 412.0]) {
        for (final scale in [1.0, 1.3]) {
          tester.view.physicalSize = Size(width, 700);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          double? areaHeight;
          double? continueTop;

          Future<void> measure({
            required LocationProvider location,
            bool presetDeliveryLocation = false,
          }) async {
            final fuel = FuelProvider(locationProvider: location);
            await _preload(fuel, tester);
            if (presetDeliveryLocation) fuel.setDeliveryLocation(_location);
            await tester.pumpWidget(_wrapShared(
              KeyedSubtree(key: UniqueKey(), child: const FuelBookingScreen()),
              fuel: fuel,
              location: location,
              textScale: scale,
            ));
            await tester.tap(find.text('Continue'));
            await tester.pump();
            await tester.tap(find.byType(FuelVehicleCard).first);
            await tester.pump();
            await tester.tap(find.text('Continue'));
            await tester.pump();
            await tester.pump();

            expect(tester.takeException(), isNull,
                reason: 'no overflow at ${width}dp × $scale');
            final area = tester.getRect(find.byKey(const Key('location_status_area')));
            areaHeight ??= area.height;
            expect(area.height, areaHeight,
                reason: 'reserved status height must stay constant between states');
            final continueRect = tester.getRect(find.text('Continue'));
            continueTop ??= continueRect.top;
            expect(continueRect.top, continueTop,
                reason: 'Continue must never move when the location status changes');
          }

          await measure(
            location: _FakeLocationProvider(
              details: const GeocodingResult(
                street: 'MG Road',
                locality: 'Indiranagar',
                city: 'Bengaluru',
                state: 'Karnataka',
                pincode: '560001',
              ),
            ),
            presetDeliveryLocation: true,
          );
          await measure(location: _LoadingLocationProvider());
          await tester.pump(const Duration(seconds: 11));
          await measure(
            location: _FakeLocationProvider(
              details: const GeocodingResult(
                street: 'MG Road',
                locality: 'Indiranagar',
                city: 'Bengaluru',
                state: 'Karnataka',
                pincode: '560001',
              ),
            ),
          );
          await measure(location: _DeniedLocationProvider());
          await measure(location: _FailingLocationProvider());
        }
      }
    });

    testWidgets('GPS success writes one consistent Step 3 state', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final location = _SlowResolvingLocationProvider();
      final fuel = FuelProvider(locationProvider: location);
      await _preload(fuel, tester);

      await tester.pumpWidget(_wrapShared(
        const FuelBookingScreen(),
        fuel: fuel,
        location: location,
      ));

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.tap(find.byType(FuelVehicleCard).first);
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      // Banner: success.
      expect(find.text('📍 Current Location Detected'), findsOneWidget);
      // Preview: shown, reading the provider model.
      expect(find.byType(DeliveryLocationCard), findsOneWidget);
      // Fields: seeded from the SAME model as the preview/provider.
      final delivery = fuel.deliveryLocation;
      expect(delivery, isNotNull);
      final addressField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Delivery Address'),
      );
      final pincodeField =
          tester.widget<TextField>(find.widgetWithText(TextField, 'Pincode'));
      expect(addressField.controller!.text, delivery!.address,
          reason: 'address field must mirror the provider model');
      expect(pincodeField.controller!.text, '560001',
          reason: 'pincode field must mirror the provider model');
      expect(delivery.pincode, '560001');
      expect(delivery.latitude, 12.9716);
      expect(delivery.longitude, 77.5946);
      expect(delivery.label, 'Current Location');
    });

    testWidgets('reopening the booking screen renders the location identically',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final location = _SlowResolvingLocationProvider();
      final fuel = FuelProvider(locationProvider: location);
      await _preload(fuel, tester);

      await tester.pumpWidget(_wrapShared(
        KeyedSubtree(key: UniqueKey(), child: const FuelBookingScreen()),
        fuel: fuel,
        location: location,
      ));
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.tap(find.byType(FuelVehicleCard).first);
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      final delivery = fuel.deliveryLocation;
      expect(delivery, isNotNull);

      // Leave the route and push a fresh FuelBookingScreen (same singleton
      // providers) — the committed location must survive.
      await tester.pumpWidget(_wrapShared(
        KeyedSubtree(key: UniqueKey(), child: const FuelBookingScreen()),
        fuel: fuel,
        location: location,
      ));
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.tap(find.byType(FuelVehicleCard).first);
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.text('📍 Current Location Detected'), findsOneWidget,
          reason: 'banner state must be identical after reopening');
      expect(find.byType(DeliveryLocationCard), findsOneWidget,
          reason: 'preview must be identical after reopening');
      final addressField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Delivery Address'),
      );
      final pincodeField =
          tester.widget<TextField>(find.widgetWithText(TextField, 'Pincode'));
      expect(addressField.controller!.text, delivery!.address,
          reason: 'address field must be identical after reopening');
      expect(pincodeField.controller!.text, '560001',
          reason: 'pincode field must be identical after reopening');

      // Flush the reopened screen's async detection hops so no timers dangle.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('geocode failure shows error + Retry, never success with empty fields',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final location = _NoAddressLocationProvider();
      final fuel = FuelProvider(locationProvider: location);
      await _preload(fuel, tester);

      await tester.pumpWidget(_wrapShared(
        const FuelBookingScreen(),
        fuel: fuel,
        location: location,
      ));

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.tap(find.byType(FuelVehicleCard).first);
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Unable to determine your location.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('📍 Current Location Detected'), findsNothing,
          reason: 'must not show success when no address was resolved');
      expect(fuel.deliveryLocation, isNull,
          reason: 'no stale delivery location may be kept');
      final addressField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Delivery Address'),
      );
      expect(addressField.controller!.text, isEmpty);
    });

    testWidgets('Continue during detection is swallowed, then works once detected',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final location = _SlowResolvingLocationProvider();
      final fuel = FuelProvider(locationProvider: location);
      await _preload(fuel, tester);

      await tester.pumpWidget(_wrapShared(
        const FuelBookingScreen(),
        fuel: fuel,
        location: location,
      ));
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.tap(find.byType(FuelVehicleCard).first);
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();

      // Detection is still in flight (address empty, fields disabled).
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text('Please enter your delivery address'), findsNothing,
          reason: 'no false address snack while GPS detection is running');
      expect(find.text('Select Fuel Station'), findsNothing,
          reason: 'must not advance while detection is still running');

      // Let detection complete, then Continue must advance.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('📍 Current Location Detected'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('Select Fuel Station'), findsOneWidget);
    });

    testWidgets('floating validation snack does not block the Continue bar',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final location = _FakeLocationProvider(
        details: const GeocodingResult(
          street: 'MG Road',
          locality: 'Indiranagar',
          city: 'Bengaluru',
          state: 'Karnataka',
          pincode: '560001',
        ),
      );
      final fuel = FuelProvider(locationProvider: location);
      await _preload(fuel, tester);

      await tester.pumpWidget(_wrapShared(
        const FuelBookingScreen(),
        fuel: fuel,
        location: location,
      ));
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.tap(find.byType(FuelVehicleCard).first);
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('📍 Current Location Detected'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('Select Fuel Station'), findsOneWidget);

      // Step 4: pressing Continue with no station shows the validation snack.
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text('Please select a fuel station'), findsOneWidget);

      // Select a station and Continue while the snack is still visible.
      final index = fuel.stations.indexWhere((s) => s.isSelectable);
      await tester.tap(find.byType(FuelStationCard).at(index));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text('Please select a fuel station'), findsOneWidget,
          reason: 'snack is still on screen');
      expect(find.text('Order Summary'), findsOneWidget,
          reason: 'floating snack must not swallow the Continue tap');
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('vehicle cards are content-sized and horizontally scrollable at 320dp',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final fuel = FuelProvider(locationProvider: _FakeLocationProvider());
      await _preload(fuel, tester);

      await tester.pumpWidget(_wrap(const FuelBookingScreen(), fuel: fuel));
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.text('Vehicle Details'), findsOneWidget);
      expect(find.byType(FuelVehicleCard), findsWidgets);
      expect(tester.takeException(), isNull);

      final horizontalList = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(horizontalList, findsOneWidget);

      final firstCard = tester.getSize(find.byType(FuelVehicleCard).first);
      expect(firstCard.height, lessThan(120),
          reason: 'card must be content-sized, not forced to the old fixed 120px box');

      if (find.byType(FuelVehicleCard).evaluate().length > 2) {
        final thirdCard = find.byType(FuelVehicleCard).at(2);
        expect(tester.getRect(thirdCard).right, greaterThan(320),
            reason: 'third card starts off-screen at 320dp and must be scrollable');
        await tester.drag(horizontalList, const Offset(-300, 0));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(tester.getRect(thirdCard).right, lessThanOrEqualTo(320),
            reason: 'third card scrolls into view');
      }
    });

    testWidgets('vehicle cards grow with text scale (responsive, zero overflow)', (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final location = _FakeLocationProvider();
      final fuel = FuelProvider(locationProvider: location);
      await _preload(fuel, tester);

      Future<double> cardHeightAt(double scale) async {
        await tester.pumpWidget(_wrapShared(
          KeyedSubtree(
            key: UniqueKey(),
            child: const FuelBookingScreen(),
          ),
          fuel: fuel,
          location: location,
          textScale: scale,
        ));
        await tester.tap(find.text('Continue'));
        await tester.pump();
        final height = tester.getSize(find.byType(FuelVehicleCard).first).height;
        expect(tester.takeException(), isNull);
        return height;
      }

      final normal = await cardHeightAt(1.0);
      final large = await cardHeightAt(1.3);
      expect(large, greaterThan(normal),
          reason: 'card height must adapt to content, not be a fixed box');
    });

    testWidgets('all 5 steps render with zero overflow and intact CTAs at 320/360/412dp',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final location = _FakeLocationProvider(
        details: const GeocodingResult(
          street: 'MG Road',
          locality: 'Indiranagar',
          city: 'Bengaluru',
          state: 'Karnataka',
          pincode: '560001',
        ),
      );
      final fuel = FuelProvider(locationProvider: location);
      await _preload(fuel, tester);

      for (final width in [320.0, 360.0, 412.0]) {
        for (final scale in [1.0, 1.3]) {
          tester.view.physicalSize = Size(width, 700);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(_wrapShared(
            KeyedSubtree(
              key: UniqueKey(),
              child: const FuelBookingScreen(),
            ),
            fuel: fuel,
            location: location,
            textScale: scale,
          ));

          // Step 1 — Fuel.
          expect(find.text('Select Fuel Type'), findsOneWidget);
          expect(find.text('Continue'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Continue'));
          await tester.pump();

          // Step 2 — Vehicle.
          expect(find.text('Vehicle Details'), findsOneWidget);
          expect(find.text('Back'), findsOneWidget);
          expect(find.text('Continue'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byType(FuelVehicleCard).first);
          await tester.pump();
          await tester.tap(find.text('Continue'));
          await tester.pump();

          // Step 3 — Location.
          expect(find.text('Delivery Location'), findsOneWidget);
          expect(find.text('Back'), findsOneWidget);
          expect(find.text('Continue'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.enterText(find.byType(TextField).first, 'MG Road, Bengaluru');
          await tester.pump();
          await tester.tap(find.text('Continue'));
          await tester.pump(const Duration(milliseconds: 900));

          // Step 4 — Station.
          expect(find.text('Select Fuel Station'), findsOneWidget);
          expect(find.text('Back'), findsOneWidget);
          expect(find.text('Continue'), findsOneWidget);
          expect(tester.takeException(), isNull);
          final index = fuel.stations.indexWhere((s) => s.isSelectable);
          await tester.ensureVisible(find.byType(FuelStationCard).at(index));
          await tester.pump();
          await tester.tap(find.byType(FuelStationCard).at(index));
          await tester.pump();
          await tester.tap(find.text('Continue'));
          await tester.pump();

          // Step 5 — Review.
          expect(find.text('Order Summary'), findsOneWidget);
          expect(find.text('Back'), findsOneWidget);
          expect(find.text('Place Order'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    });
  });

  // ── Widget: Timeline / Quantity ───────────────────────────────────────

  group('TrackingTimeline', () {
    testWidgets('renders all 7 states with current highlighted', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TrackingTimeline(status: OrderStatus.enRoute)),
        ),
      );
      expect(find.text('Requested'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Fuel Packed'), findsOneWidget);
      expect(find.text('Delivery Partner Assigned'), findsOneWidget);
      expect(find.text('En Route'), findsOneWidget);
      expect(find.text('Arrived'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Current status'), findsOneWidget);
    });

    testWidgets('delivered marks all steps complete', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TrackingTimeline(status: OrderStatus.delivered)),
        ),
      );
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(7));
      expect(find.text('Current status'), findsNothing);
    });
  });

  group('QuantitySelector', () {
    testWidgets('custom option opens a slider dialog', (tester) async {
      var quantity = 5.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantitySelector(
              quantity: quantity,
              onChanged: (v) => quantity = v,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      expect(find.text('Custom Quantity'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Custom Quantity'), findsNothing);
      expect(quantity, 5.0);
    });
  });
}
