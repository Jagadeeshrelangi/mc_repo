// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mecha_connect/app_wiring.dart';
import 'package:mecha_connect/auth/auth_text_field.dart';
import 'package:mecha_connect/auth/password_field.dart';
import 'package:mecha_connect/bottom_bar/bottom_navigation.dart';
import 'package:mecha_connect/features/auth/providers/auth_provider.dart';
import 'package:mecha_connect/features/auth/screens/login_screen.dart';
import 'package:mecha_connect/services/api_client.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestApp() {
    return MultiProvider(
      providers: buildRootProviders(),
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('Real Device/Emulator Authentication End-to-End', () {
    testWidgets('1. Invalid credentials -> hits backend -> 401 -> shows error -> stays on Login', (tester) async {
      SharedPreferences.setMockInitialValues({});
      ApiClient.resetInstance();

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final authProvider = tester.element(find.byType(LoginScreen)).read<AuthProvider>();

      // Enter invalid credentials
      final emailFinder = find.byType(AuthTextField);
      final passFinder = find.byType(PasswordField);

      expect(emailFinder, findsOneWidget);
      expect(passFinder, findsOneWidget);

      await tester.enterText(find.descendant(of: emailFinder, matching: find.byType(TextFormField)), 'random_unregistered@example.com');
      await tester.enterText(find.descendant(of: passFinder, matching: find.byType(TextFormField)), 'WrongPass123!');
      await tester.pumpAndSettle();

      // Tap Login
      final loginButton = find.text('Login');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Assert user stays on LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.error, isNotNull);
      print('[EMULATOR TEST 1] Invalid login correctly rejected with 401. Error message: "${authProvider.error}"');
    });

    testWidgets('2. Valid credentials -> hits backend -> 200 -> stores real JWT -> navigates to Home -> performs protected request', (tester) async {
      SharedPreferences.setMockInitialValues({});
      ApiClient.resetInstance();
      final apiClient = ApiClient(); // dynamic baseUrl resolves http://10.0.2.2:8000 on Android

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final authProvider = tester.element(find.byType(LoginScreen)).read<AuthProvider>();

      // Enter valid registered test credentials
      final emailFinder = find.byType(AuthTextField);
      final passFinder = find.byType(PasswordField);

      await tester.enterText(find.descendant(of: emailFinder, matching: find.byType(TextFormField)), 'testdriver@example.com');
      await tester.enterText(find.descendant(of: passFinder, matching: find.byType(TextFormField)), 'TestPassword123!');
      await tester.pumpAndSettle();

      // Tap Login
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Assert user is authenticated, transitioned to BottomNavigation (Home)
      expect(authProvider.isLoggedIn, isTrue);
      expect(find.byType(BottomNavigation), findsOneWidget);
      final accessToken = await apiClient.getAccessToken();
      expect(accessToken, isNotNull);
      expect(accessToken!.isNotEmpty, isTrue);
      print('[EMULATOR TEST 2] Valid login succeeded with 200 OK. Navigated to BottomNavigation (Home). JWT saved.');

      // 3. Verify Home Screen displays real backend user name and truthful vehicle state
      expect(find.text('Test Driver'), findsOneWidget);
      expect(find.text('Jagadeesh'), findsNothing);
      expect(find.text('No vehicle added yet'), findsOneWidget);
      print('[EMULATOR TEST 3] Home Screen displays real authenticated user "Test Driver" and truthful "No vehicle added yet" empty state.');

      // 4. Perform a protected request with the real JWT
      final protectedRes = await apiClient.get('/api/v1/fuel/orders', requiresAuth: true);
      expect(protectedRes, isA<List>());
      print('[EMULATOR TEST 4] Protected endpoint GET /api/v1/fuel/orders returned 200 OK with valid Bearer JWT: ${protectedRes.length} orders retrieved.');

      // 5. Test real Vehicle Persistence Flow over real FastAPI + Supabase
      print('[EMULATOR TEST 5] Testing real Vehicle Persistence over Android Emulator...');
      final createdVehRes = await apiClient.post(
        '/api/v1/vehicles',
        body: {
          'brand': 'Hyundai',
          'model': 'Venue',
          'registration': 'KA 03 XY 9999',
          'fuel_type': 'petrol',
          'health_score': 94,
        },
        requiresAuth: true,
      );
      expect(createdVehRes, isA<Map<String, dynamic>>());
      final vehId = (createdVehRes as Map<String, dynamic>)['id'];
      expect(vehId, isNotNull);
      print('[EMULATOR TEST 5a] Created vehicle in Supabase via FastAPI: ID=$vehId');

      // 6. Verify GET /api/v1/vehicles
      final listVehRes = await apiClient.get('/api/v1/vehicles', requiresAuth: true);
      expect(listVehRes, isA<List>());
      expect((listVehRes as List).any((v) => v['id'] == vehId), isTrue);
      print('[EMULATOR TEST 5b] GET /api/v1/vehicles verified created vehicle in list.');

      // 7. Verify DELETE /api/v1/vehicles/{id}
      await apiClient.delete('/api/v1/vehicles/$vehId', requiresAuth: true);
      final afterDelList = await apiClient.get('/api/v1/vehicles', requiresAuth: true);
      expect((afterDelList as List).any((v) => v['id'] == vehId), isFalse);
      print('[EMULATOR TEST 5c] DELETE /api/v1/vehicles/$vehId verified cleaned up.');

      // 8. Test real Profile Persistence Flow over real FastAPI + Supabase
      print('[EMULATOR TEST 6] Testing real Profile Persistence over Android Emulator...');
      final patchProfileRes = await apiClient.patch(
        '/api/v1/users/me',
        body: {
          'name': 'Test Driver Updated',
          'gender': 'Male',
          'emergency_contact_name': 'Jane Driver',
          'emergency_contact_phone': '+919876543210',
        },
        requiresAuth: true,
      );
      expect(patchProfileRes, isA<Map<String, dynamic>>());
      expect((patchProfileRes as Map<String, dynamic>)['name'], 'Test Driver Updated');
      expect(patchProfileRes['emergency_contact_name'], 'Jane Driver');
      print('[EMULATOR TEST 6a] PATCH /api/v1/users/me verified updated profile.');

      final getProfileRes = await apiClient.get('/api/v1/users/me', requiresAuth: true);
      expect(getProfileRes, isA<Map<String, dynamic>>());
      expect((getProfileRes as Map<String, dynamic>)['name'], 'Test Driver Updated');
      expect(getProfileRes['gender'], 'Male');
      print('[EMULATOR TEST 6b] GET /api/v1/users/me verified persistence in Supabase.');

      // Reset profile name back to 'Test Driver'
      await apiClient.patch(
        '/api/v1/users/me',
        body: {'name': 'Test Driver'},
        requiresAuth: true,
      );
      print('[EMULATOR TEST 6c] Profile name reset back to "Test Driver".');

      // 9. Test real Address Persistence Flow over Android Emulator
      print('[EMULATOR TEST 7] Testing real Address Persistence over Android Emulator...');
      final createdAddrRes = await apiClient.post(
        '/api/v1/addresses',
        body: {
          'label': 'home',
          'address': 'Flat 204, Green Heights, Bengaluru 560001',
          'latitude': 12.9716,
          'longitude': 77.5946,
          'is_default': true,
        },
        requiresAuth: true,
      );
      expect(createdAddrRes, isA<Map<String, dynamic>>());
      final addrId = (createdAddrRes as Map<String, dynamic>)['id'];
      expect(addrId, isNotNull);
      print('[EMULATOR TEST 7a] Created address in Supabase: ID=$addrId');

      final listAddrRes = await apiClient.get('/api/v1/addresses', requiresAuth: true);
      expect(listAddrRes, isA<List>());
      expect((listAddrRes as List).any((a) => a['id'] == addrId), isTrue);
      print('[EMULATOR TEST 7b] GET /api/v1/addresses verified address in list.');

      await apiClient.delete('/api/v1/addresses/$addrId', requiresAuth: true);
      final afterDelAddrList = await apiClient.get('/api/v1/addresses', requiresAuth: true);
      expect((afterDelAddrList as List).any((a) => a['id'] == addrId), isFalse);
      print('[EMULATOR TEST 7c] DELETE /api/v1/addresses/$addrId verified cleaned up.');

      // 10. Test real Wallet, Rewards, and Notification Settings over Android Emulator
      print('[EMULATOR TEST 8] Testing real Wallet, Rewards, Notifications over Android Emulator...');
      final walletRes = await apiClient.get('/api/v1/wallet', requiresAuth: true);
      expect(walletRes, isA<Map<String, dynamic>>());
      print('[EMULATOR TEST 8a] GET /api/v1/wallet returned balance=${(walletRes as Map<String, dynamic>)['balance']}.');

      final rewardsRes = await apiClient.get('/api/v1/rewards', requiresAuth: true);
      expect(rewardsRes, isA<Map<String, dynamic>>());
      print('[EMULATOR TEST 8b] GET /api/v1/rewards returned redeemable=${(rewardsRes as Map<String, dynamic>)['redeemable_points']}.');

      final notifRes = await apiClient.get('/api/v1/notification-settings', requiresAuth: true);
      expect(notifRes, isA<Map<String, dynamic>>());
      print('[EMULATOR TEST 8c] GET /api/v1/notification-settings returned push=${(notifRes as Map<String, dynamic>)['push']}.');

      // 11. Test real Fuel Delivery Order Flow over Android Emulator
      print('[EMULATOR TEST 9] Testing real Fuel Order creation & lifecycle...');
      final fuelOrderRes = await apiClient.post(
        '/api/v1/fuel/orders',
        body: {
          'fuel_type': 'petrol',
          'quantity': 10.0,
          'vehicle_type': 'Car',
          'vehicle_name': 'Hyundai Venue',
          'vehicle_number': 'KA 03 XY 9999',
          'station_name': 'Main Road Filling Station',
          'brand': 'Indian Oil',
          'price_per_litre': 102.5,
          'delivery_label': 'Home',
          'delivery_address': 'Flat 204, Green Heights, Bengaluru 560001',
          'lat': 12.9716,
          'lng': 77.5946,
          'payment_method': 'UPI',
        },
        requiresAuth: true,
      );
      expect(fuelOrderRes, isA<Map<String, dynamic>>());
      final fuelOrderId = (fuelOrderRes as Map<String, dynamic>)['id'];
      expect(fuelOrderId, isNotNull);
      print('[EMULATOR TEST 9a] Created Fuel Order in Supabase: ID=$fuelOrderId');

      final getFuelOrderRes = await apiClient.get('/api/v1/fuel/orders/$fuelOrderId', requiresAuth: true);
      expect(getFuelOrderRes, isA<Map<String, dynamic>>());
      expect((getFuelOrderRes as Map<String, dynamic>)['id'], fuelOrderId);
      print('[EMULATOR TEST 9b] GET /api/v1/fuel/orders/$fuelOrderId verified.');

      final cancelFuelOrderRes = await apiClient.patch(
        '/api/v1/fuel/orders/$fuelOrderId/status',
        body: {'status': 'cancelled'},
        requiresAuth: true,
      );
      expect(cancelFuelOrderRes, isA<Map<String, dynamic>>());
      expect((cancelFuelOrderRes as Map<String, dynamic>)['status'], 'cancelled');
      print('[EMULATOR TEST 9c] PATCH /api/v1/fuel/orders/$fuelOrderId/status cancelled successfully.');

      // 12. Test real Marketplace Order Flow over Android Emulator
      print('[EMULATOR TEST 10] Testing real Marketplace Order creation & activity ledger...');
      final mkpOrderRes = await apiClient.post(
        '/api/v1/marketplace/orders',
        body: {
          'address': 'Flat 204, Green Heights, Bengaluru 560001',
          'payment_method': 'UPI',
          'items': [
            {
              'product_id': 'prod_001',
              'product_name': 'Synthetic Engine Oil 5W-40',
              'brand': 'Mobil 1',
              'quantity': 1,
              'unit_price': 1499.0,
            }
          ],
        },
        requiresAuth: true,
      );
      expect(mkpOrderRes, isA<Map<String, dynamic>>());
      final mkpOrderId = (mkpOrderRes as Map<String, dynamic>)['id'];
      expect(mkpOrderId, isNotNull);
      print('[EMULATOR TEST 10a] Created Marketplace Order in Supabase: ID=$mkpOrderId');

      final getMkpOrderRes = await apiClient.get('/api/v1/marketplace/orders/$mkpOrderId', requiresAuth: true);
      expect(getMkpOrderRes, isA<Map<String, dynamic>>());
      expect((getMkpOrderRes as Map<String, dynamic>)['id'], mkpOrderId);
      print('[EMULATOR TEST 10b] GET /api/v1/marketplace/orders/$mkpOrderId verified.');

      final activityRes = await apiClient.get('/api/v1/marketplace/activity', requiresAuth: true);
      expect(activityRes, isA<List>());
      expect((activityRes as List).isNotEmpty, isTrue);
      print('[EMULATOR TEST 10c] GET /api/v1/marketplace/activity verified: ${activityRes.length} ledger entries.');
    });
  });
}
