import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mecha_connect/features/mechanic/providers/mechanic_provider.dart';
import 'package:mecha_connect/features/mechanic/screens/vehicle_form_screen.dart';
import 'package:mecha_connect/services/geocoding_service.dart';
import 'package:mecha_connect/services/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocationProvider extends LocationProvider {
  _FakeLocationProvider({
    this.hasLocationValue = false,
    this.permission = LocationPermissionState.granted,
    this.details,
    this.gpsCompleter,
  });

  bool hasLocationValue;
  LocationPermissionState permission;
  GeocodingResult? details;
  Completer<bool>? gpsCompleter;

  @override
  bool get hasLocation => hasLocationValue;

  @override
  GeocodingResult? get currentAddressDetails => details;

  @override
  String get currentAddress => details?.fullAddress ?? '';

  @override
  LocationPermissionState get permissionState => permission;

  @override
  Future<void> checkAndRequestPermission() async {}

  @override
  Future<bool> getCurrentLocation() {
    if (gpsCompleter != null) return gpsCompleter!.future;
    return Future.value(hasLocationValue);
  }
}

Widget _wrapWithLocation(Widget child, LocationProvider location) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LocationProvider>(create: (_) => location),
      ChangeNotifierProvider<MechanicProvider>(create: (_) => MechanicProvider()),
    ],
    child: MaterialApp(home: child),
  );
}

final _addressFinder = find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == 'House no, street, area, city',
);
final _pincodeFinder = find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == 'Pincode',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GeocodingResult', () {
    test('builds full and short address from structured parts', () {
      const result = GeocodingResult(
        street: 'MG Road',
        locality: 'Indiranagar',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560001',
      );
      expect(result.fullAddress, 'MG Road, Indiranagar, Bengaluru, Karnataka, 560001');
      expect(result.shortAddress, 'MG Road, Indiranagar, Bengaluru');
    });

    test('reports empty when no parts available', () {
      const result = GeocodingResult();
      expect(result.isEmpty, isTrue);
      expect(result.fullAddress, isEmpty);
    });
  });

  group('VehicleFormScreen auto location', () {
    testWidgets('auto-fills address and pincode from detected location', (tester) async {
      final location = _FakeLocationProvider(
        hasLocationValue: true,
        details: const GeocodingResult(
          street: 'MG Road',
          locality: 'Indiranagar',
          city: 'Bengaluru',
          state: 'Karnataka',
          pincode: '560001',
        ),
      );
      await tester.pumpWidget(_wrapWithLocation(const VehicleFormPage(), location));
      await tester.pumpAndSettle();

      expect(find.text('📍 Current Location Detected'), findsOneWidget);
      expect(tester.widget<TextField>(_addressFinder).controller!.text,
          'MG Road, Indiranagar, Bengaluru, Karnataka, 560001');
      expect(tester.widget<TextField>(_pincodeFinder).controller!.text, '560001');
    });

    testWidgets('shows loading state and disables only the location fields', (tester) async {
      final completer = Completer<bool>();
      final location = _FakeLocationProvider(
        permission: LocationPermissionState.granted,
        gpsCompleter: completer,
      );
      await tester.pumpWidget(_wrapWithLocation(const VehicleFormPage(), location));
      await tester.pump();
      await tester.pump();

      expect(find.text('Loading current location...'), findsOneWidget);
      expect(tester.widget<TextField>(_addressFinder).enabled, isFalse);
      expect(tester.widget<TextField>(_pincodeFinder).enabled, isFalse);

      // Rest of the form remains usable.
      expect(find.text('Bike'), findsOneWidget);

      completer.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('Unable to determine your location.'), findsOneWidget);
    });

    testWidgets('shows permission denied with Retry and Enter Manually', (tester) async {
      final location = _FakeLocationProvider(permission: LocationPermissionState.denied);
      await tester.pumpWidget(_wrapWithLocation(const VehicleFormPage(), location));
      await tester.pumpAndSettle();

      expect(find.text('Location permission denied.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Enter Manually'), findsOneWidget);
    });

    testWidgets('shows error banner when GPS is unavailable', (tester) async {
      final location = _FakeLocationProvider(permission: LocationPermissionState.granted);
      await tester.pumpWidget(_wrapWithLocation(const VehicleFormPage(), location));
      await tester.pumpAndSettle();

      expect(find.text('Unable to determine your location.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Enter Manually'), findsOneWidget);
    });

    testWidgets('Retry re-runs detection and auto-fills fields', (tester) async {
      final location = _FakeLocationProvider(permission: LocationPermissionState.denied);
      await tester.pumpWidget(_wrapWithLocation(const VehicleFormPage(), location));
      await tester.pumpAndSettle();
      expect(find.text('Location permission denied.'), findsOneWidget);

      location.permission = LocationPermissionState.granted;
      location.hasLocationValue = true;
      location.details = const GeocodingResult(street: 'Park Street', locality: 'Kolkata', pincode: '700016');

      await tester.ensureVisible(find.text('Retry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('📍 Current Location Detected'), findsOneWidget);
      expect(tester.widget<TextField>(_addressFinder).controller!.text, contains('Park Street'));
    });

    testWidgets('Enter Manually dismisses banner and keeps fields editable', (tester) async {
      final location = _FakeLocationProvider(permission: LocationPermissionState.denied);
      await tester.pumpWidget(_wrapWithLocation(const VehicleFormPage(), location));
      await tester.pumpAndSettle();
      expect(find.text('Location permission denied.'), findsOneWidget);

      await tester.ensureVisible(find.text('Enter Manually'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enter Manually'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      expect(find.text('Location permission denied.'), findsNothing);
      expect(find.text('Use Current Location'), findsOneWidget);
      expect(tester.widget<TextField>(_addressFinder).enabled, isTrue);
    });
  });
}
