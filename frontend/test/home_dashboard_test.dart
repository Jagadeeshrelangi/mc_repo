import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:mecha_connect/features/home/providers/home_provider.dart';
import 'package:mecha_connect/features/home/repositories/home_repository.dart';
import 'package:mecha_connect/features/home/screens/home_screen.dart';
import 'package:mecha_connect/features/home/screens/home_search_screen.dart';
import 'package:mecha_connect/services/api_client.dart';
import 'package:mecha_connect/services/geocoding_service.dart';
import 'package:mecha_connect/services/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Widget _wrap(Widget child, {HomeRepository? repository}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => HomeProvider(repository ?? HomeRepository()),
      ),
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
    ApiClient.resetInstance();
  });

  testWidgets('HomeDashboard renders sections after load with truthful empty states', (tester) async {
    final mockHttp = MockClient((request) async {
      return http.Response('[]', 200);
    });

    final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
    final repo = HomeRepository(apiClient: apiClient);

    await tester.pumpWidget(_wrap(const HomeDashboard(), repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Quick Services'), findsOneWidget);
    expect(find.text('Nearby Services'), findsOneWidget);
    expect(find.text('Marketplace'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('Offers'), findsOneWidget);

    // Truthful empty states
    expect(find.text('No vehicle added yet'), findsOneWidget);
    expect(find.text('No nearby services'), findsOneWidget);
    expect(find.text('Marketplace is empty'), findsOneWidget);
    expect(find.text('No activity yet'), findsOneWidget);
    expect(find.text('No offers right now'), findsOneWidget);
  });

  testWidgets('HomeDashboard renders real user profile name from backend', (tester) async {
    final mockHttp = MockClient((request) async {
      if (request.url.path == '/api/v1/users/me') {
        return http.Response(
          jsonEncode({
            'id': 'u-123',
            'name': 'Priya Sharma',
            'email': 'priya@example.com',
            'phone': '+919876543210',
            'role': 'customer',
          }),
          200,
        );
      }
      return http.Response('[]', 200);
    });

    final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
    await apiClient.saveTokens(accessToken: 'valid-jwt', refreshToken: 'valid-refresh');
    final repo = HomeRepository(apiClient: apiClient);

    await tester.pumpWidget(_wrap(const HomeDashboard(), repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('Jagadeesh'), findsNothing);
  });

  testWidgets('HomeDashboard LocationCard shows the live location address', (tester) async {
    await tester.pumpWidget(_wrap(const HomeDashboard()));
    await tester.pumpAndSettle();

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
  testWidgets('HomeDashboard aggregates fuel, mechanic, and marketplace activities sorted by date', (tester) async {
    final mockHttp = MockClient((request) async {
      if (request.url.path == '/api/v1/fuel/orders') {
        return http.Response(
          jsonEncode([
            {
              'id': 'fo-1',
              'fuel_type': 'petrol',
              'quantity': 5.0,
              'status': 'delivered',
              'created_at': '2026-08-25T10:00:00Z',
            }
          ]),
          200,
        );
      }
      if (request.url.path == '/api/v1/mechanic/bookings') {
        return http.Response(
          jsonEncode([
            {
              'id': 'b-1',
              'status': 'in_progress',
              'created_at': '2026-08-25T14:00:00Z',
            }
          ]),
          200,
        );
      }
      if (request.url.path == '/api/v1/marketplace/orders') {
        return http.Response(
          jsonEncode([
            {
              'id': 'ord-1',
              'status': 'placed',
              'created_at': '2026-08-25T12:00:00Z',
              'items': [
                {'product_name': 'Synthetic Engine Oil 5W-30'}
              ],
            }
          ]),
          200,
        );
      }
      return http.Response('[]', 200);
    });

    final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
    await apiClient.saveTokens(accessToken: 'valid-jwt', refreshToken: 'valid-refresh');
    final repo = HomeRepository(apiClient: apiClient);

    await tester.pumpWidget(_wrap(const HomeDashboard(), repository: repo));
    await tester.pumpAndSettle();

    // Verify all 3 activity items are rendered
    expect(find.text('5.0L PETROL Delivery'), findsOneWidget);
    expect(find.text('Mechanic Service'), findsOneWidget);
    expect(find.text('Synthetic Engine Oil 5W-30'), findsOneWidget);

    // Verify statuses
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Placed'), findsOneWidget);
  });

  testWidgets('HomeDashboard handles partial domain failure gracefully in activities', (tester) async {
    final mockHttp = MockClient((request) async {
      if (request.url.path == '/api/v1/fuel/orders') {
        return http.Response(
          jsonEncode([
            {
              'id': 'fo-1',
              'fuel_type': 'diesel',
              'quantity': 10.0,
              'status': 'completed',
              'created_at': '2026-08-25T10:00:00Z',
            }
          ]),
          200,
        );
      }
      if (request.url.path == '/api/v1/mechanic/bookings') {
        return http.Response('Internal Server Error', 500);
      }
      if (request.url.path == '/api/v1/marketplace/orders') {
        return http.Response('Internal Server Error', 500);
      }
      return http.Response('[]', 200);
    });

    final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
    await apiClient.saveTokens(accessToken: 'valid-jwt', refreshToken: 'valid-refresh');
    final repo = HomeRepository(apiClient: apiClient);

    await tester.pumpWidget(_wrap(const HomeDashboard(), repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('10.0L DIESEL Delivery'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('HomeDashboard renders real default vehicle from backend', (tester) async {
    final mockHttp = MockClient((request) async {
      if (request.url.path == '/api/v1/vehicles') {
        return http.Response(
          jsonEncode([
            {
              'id': 'veh-uuid-1',
              'user_id': 'user-uuid-1',
              'brand': 'Hyundai',
              'model': 'Creta',
              'registration': 'KA 05 MN 1234',
              'fuel_type': 'petrol',
              'is_default': true,
              'health_score': 95,
              'created_at': '2026-08-25T10:00:00Z',
              'updated_at': '2026-08-25T10:00:00Z',
            }
          ]),
          200,
        );
      }
      return http.Response('[]', 200);
    });

    final apiClient = ApiClient(baseUrl: 'http://test-server.local', client: mockHttp);
    await apiClient.saveTokens(accessToken: 'valid-jwt', refreshToken: 'valid-refresh');
    final repo = HomeRepository(apiClient: apiClient);

    await tester.pumpWidget(_wrap(const HomeDashboard(), repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Hyundai Creta'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget);
    expect(find.text('No vehicle added yet'), findsNothing);
  });
}

