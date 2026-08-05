import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mecha_connect/features/home/providers/home_provider.dart';
import 'package:mecha_connect/features/home/repositories/home_repository.dart';
import 'package:mecha_connect/features/home/screens/home_screen.dart';
import 'package:mecha_connect/features/home/screens/home_search_screen.dart';
import 'package:mecha_connect/services/geocoding_service.dart';
import 'package:mecha_connect/services/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LocationProvider whose permission/GPS methods are inert, so pumping the
/// Home dashboard never touches platform channels. `hasLocation` reports true
/// with a resolved address so the Home LocationCard shows the live address.
class _FakeLocationProvider extends LocationProvider {
  @override
  bool get hasLocation => true;

  @override
  LatLng? get currentLatLng => const LatLng(17.1, 82.0);

  @override
  GeocodingResult? get currentAddressDetails => const GeocodingResult(
        street: 'MG Road',
        locality: 'Indiranagar',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560001',
      );

  @override
  String get currentAddress => 'MG Road, Indiranagar, Bengaluru';

  @override
  String get selectedAddress => 'MG Road, Indiranagar, Bengaluru';

  @override
  LocationPermissionState get permissionState => LocationPermissionState.granted;

  @override
  Future<void> checkAndRequestPermission() async {}

  @override
  Future<bool> getCurrentLocation() async => true;
}

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => HomeProvider(HomeRepository())),
      ChangeNotifierProvider<LocationProvider>(
        create: (_) => _FakeLocationProvider(),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HomeDashboard renders sections after load', (tester) async {
    await tester.pumpWidget(_wrap(const HomeDashboard()));
    await tester.pumpAndSettle();

    expect(find.text('Quick Services'), findsOneWidget);
    expect(find.text('Nearby Services'), findsOneWidget);
    expect(find.text('Marketplace'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('Offers'), findsOneWidget);
  });

  testWidgets('HomeDashboard LocationCard shows the live location address',
      (tester) async {
    await tester.pumpWidget(_wrap(const HomeDashboard()));
    await tester.pumpAndSettle();

    // The shared LocationProvider's detected address wins over the static
    // mock ("Surampalem, Andhra Pradesh") so the card is never stale.
    expect(find.text('MG Road, Indiranagar, Bengaluru'), findsOneWidget);
    expect(find.text('Surampalem, Andhra Pradesh'), findsNothing);
  });

  testWidgets('HomeSearchScreen filters quick services by query', (tester) async {
    await tester.pumpWidget(_wrap(const HomeSearchScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Mechanic');
    await tester.pumpAndSettle();

    expect(find.text('Mechanic'), findsOneWidget);
    expect(find.text('Fuel'), findsNothing);
  });
}
