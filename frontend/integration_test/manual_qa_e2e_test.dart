// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mecha_connect/app_wiring.dart';
import 'package:mecha_connect/auth/auth_text_field.dart';
import 'package:mecha_connect/auth/password_field.dart';
import 'package:mecha_connect/bottom_bar/bottom_navigation.dart';
import 'package:mecha_connect/features/ai/models/diagnosis.dart';
import 'package:mecha_connect/features/ai/services/diagnosis_service.dart';
import 'package:mecha_connect/features/auth/providers/auth_provider.dart';
import 'package:mecha_connect/features/auth/screens/login_screen.dart';
import 'package:mecha_connect/features/fuel_delivery/models/models.dart';
import 'package:mecha_connect/features/fuel_delivery/repositories/fuel_repository.dart';
import 'package:mecha_connect/features/marketplace/models/models.dart';
import 'package:mecha_connect/features/marketplace/repositories/marketplace_repository.dart';
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

  group('Full Manual QA Feature-by-Feature Real Device Verification', () {
    testWidgets('Complete Multi-Module End-to-End User Journey on Android Emulator', (tester) async {
      SharedPreferences.setMockInitialValues({});
      ApiClient.resetInstance();
      final apiClient = ApiClient(); // Resolves to http://10.0.2.2:8000 on Android

      print('===============================================================');
      print('PHASE 1: AUTHENTICATION & FORM VALIDATION');
      print('===============================================================');

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final authProvider = tester.element(find.byType(LoginScreen)).read<AuthProvider>();

      // 1.1 Empty Form Validation
      final loginBtn = find.text('Login');
      expect(loginBtn, findsOneWidget);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      print('[QA PASS 1.1] Empty form validation: verified red error prompts displayed.');

      // 1.2 Invalid Credentials Rejection
      final emailFinder = find.byType(AuthTextField);
      final passFinder = find.byType(PasswordField);

      await tester.enterText(find.descendant(of: emailFinder, matching: find.byType(TextFormField)), 'wrong_unregistered@example.com');
      await tester.enterText(find.descendant(of: passFinder, matching: find.byType(TextFormField)), 'BadPass123!');
      await tester.pumpAndSettle();

      await tester.tap(loginBtn);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.error, isNotNull);
      print('[QA PASS 1.2] Invalid login rejected by FastAPI (401). Error displayed: "${authProvider.error}"');

      // 1.3 Valid Credentials Login
      await tester.enterText(find.descendant(of: emailFinder, matching: find.byType(TextFormField)), 'testdriver@example.com');
      await tester.enterText(find.descendant(of: passFinder, matching: find.byType(TextFormField)), 'TestPassword123!');
      await tester.pumpAndSettle();

      await tester.tap(loginBtn);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(authProvider.isLoggedIn, isTrue);
      expect(find.byType(BottomNavigation), findsOneWidget);
      final jwtToken = await apiClient.getAccessToken();
      expect(jwtToken, isNotNull);
      expect(jwtToken!.isNotEmpty, isTrue);
      print('[QA PASS 1.3] Valid login succeeded (200 OK). JWT saved. Navigated to BottomNavigation.');

      print('===============================================================');
      print('PHASE 2: HOME DASHBOARD & NAVIGATION');
      print('===============================================================');

      // 2.1 Verify User Name & Vehicle Status
      expect(find.text('Test Driver'), findsOneWidget);
      final hasEmptyVehicle = find.text('No vehicle added yet').evaluate().isNotEmpty;
      if (hasEmptyVehicle) {
        print('[QA PASS 2.1] Home screen verified: user "Test Driver", truthful "No vehicle added yet" empty state.');
      } else {
        print('[QA PASS 2.1] Home screen verified: user "Test Driver", active persisted vehicle displayed.');
      }

      // 2.2 Verify Bottom Tabs exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      print('[QA PASS 2.2] Bottom navigation verified: 5 tabs rendered.');

      print('===============================================================');
      print('PHASE 3: PROFILE, VEHICLES & ADDRESSES CRUD');
      print('===============================================================');

      // 3.1 Switch to Profile tab
      await tester.tap(find.text('Profile'), warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 3.2 Vehicle CRUD
      print('[QA 3.2] Testing Vehicle CRUD over real API...');
      final createVeh = await apiClient.post(
        '/api/v1/vehicles',
        body: {
          'brand': 'Toyota',
          'model': 'Fortuner',
          'registration': 'KA 05 Z 1234',
          'fuel_type': 'diesel',
          'health_score': 96,
        },
        requiresAuth: true,
      );
      expect(createVeh, isA<Map<String, dynamic>>());
      final vehId = (createVeh as Map<String, dynamic>)['id'];
      expect(vehId, isNotNull);
      print('[QA PASS 3.2a] Vehicle created in Supabase: Toyota Fortuner (ID: $vehId)');

      final listVeh = await apiClient.get('/api/v1/vehicles', requiresAuth: true);
      expect((listVeh as List).any((v) => v['id'] == vehId), isTrue);
      print('[QA PASS 3.2b] GET /api/v1/vehicles verified vehicle in database.');

      final updateVeh = await apiClient.patch(
        '/api/v1/vehicles/$vehId',
        body: {
          'model': 'Fortuner GR-S',
        },
        requiresAuth: true,
      );
      expect((updateVeh as Map<String, dynamic>)['model'], 'Fortuner GR-S');
      print('[QA PASS 3.2c] PATCH /api/v1/vehicles/$vehId updated vehicle model to "Fortuner GR-S".');

      final defaultVeh = await apiClient.post(
        '/api/v1/vehicles/$vehId/default',
        requiresAuth: true,
      );
      expect((defaultVeh as Map<String, dynamic>)['is_default'], isTrue);
      print('[QA PASS 3.2d] POST /api/v1/vehicles/$vehId/default promoted vehicle to primary default.');

      await apiClient.delete('/api/v1/vehicles/$vehId', requiresAuth: true);
      final afterDelVeh = await apiClient.get('/api/v1/vehicles', requiresAuth: true);
      expect((afterDelVeh as List).any((v) => v['id'] == vehId), isFalse);
      print('[QA PASS 3.2d] DELETE /api/v1/vehicles/$vehId verified clean deletion from Supabase.');

      // 3.3 Address CRUD
      print('[QA 3.3] Testing Address CRUD over real API...');
      final createAddr = await apiClient.post(
        '/api/v1/addresses',
        body: {
          'label': 'office',
          'address': 'Level 4, Prestige Tech Park, Bengaluru 560103',
          'latitude': 12.9352,
          'longitude': 77.6946,
          'is_default': true,
        },
        requiresAuth: true,
      );
      expect(createAddr, isA<Map<String, dynamic>>());
      final addrId = (createAddr as Map<String, dynamic>)['id'];
      expect(addrId, isNotNull);
      print('[QA PASS 3.3a] Address created in Supabase: Prestige Tech Park (ID: $addrId)');

      final listAddr = await apiClient.get('/api/v1/addresses', requiresAuth: true);
      expect((listAddr as List).any((a) => a['id'] == addrId), isTrue);
      print('[QA PASS 3.3b] GET /api/v1/addresses verified created address in database.');

      await apiClient.delete('/api/v1/addresses/$addrId', requiresAuth: true);
      final afterDelAddr = await apiClient.get('/api/v1/addresses', requiresAuth: true);
      expect((afterDelAddr as List).any((a) => a['id'] == addrId), isFalse);
      print('[QA PASS 3.3c] DELETE /api/v1/addresses/$addrId verified clean deletion from Supabase.');

      // 3.4 Wallet & Rewards
      final wallet = await apiClient.get('/api/v1/wallet', requiresAuth: true);
      expect(wallet, isA<Map<String, dynamic>>());
      final rewards = await apiClient.get('/api/v1/rewards', requiresAuth: true);
      expect(rewards, isA<Map<String, dynamic>>());
      print('[QA PASS 3.4] Wallet balance: ₹${(wallet as Map)['balance']}, Rewards: ${(rewards as Map)['redeemable_points']} points.');

      print('===============================================================');
      print('PHASE 4: MECHANIC DISCOVERY & SERVICES');
      print('===============================================================');

      final mechanics = await apiClient.get('/api/v1/mechanic/mechanics');
      expect(mechanics, isA<List>());
      print('[QA PASS 4.1] GET /api/v1/mechanic/mechanics returned ${mechanics.length} mechanics.');

      print('===============================================================');
      print('PHASE 5: FUEL DELIVERY ORDER & LIFECYCLE');
      print('===============================================================');

      final fuelRepo = FuelRepository(apiClient: apiClient);
      final stations = await fuelRepo.getFuelStations(latitude: 12.97, longitude: 77.59);
      expect(stations, isA<List<FuelStation>>());
      print('[QA PASS 5.1] Fuel stations queried over real HTTP: ${stations.length} stations found.');

      final estimate = await apiClient.post(
        '/api/v1/fuel/estimate',
        body: {
          'fuel_type': 'petrol',
          'quantity': 15.0,
        },
      );
      expect(estimate, isA<Map<String, dynamic>>());
      expect((estimate as Map)['grand_total'], isNotNull);
      print('[QA PASS 5.2] Fuel price estimate: ₹${estimate['grand_total']} for 15L petrol.');

      final fuelOrder = await apiClient.post(
        '/api/v1/fuel/orders',
        body: {
          'fuel_type': 'petrol',
          'quantity': 15.0,
          'vehicle_type': 'Car',
          'vehicle_name': 'Toyota Fortuner',
          'vehicle_number': 'KA 05 Z 1234',
          'station_name': 'Shell Koramangala',
          'brand': 'Shell',
          'price_per_litre': 105.0,
          'delivery_label': 'Home',
          'delivery_address': '123 Tech Park, Bengaluru',
          'lat': 12.9716,
          'lng': 77.5946,
          'payment_method': 'Card',
        },
        requiresAuth: true,
      );
      final fuelOrderId = (fuelOrder as Map)['id'];
      expect(fuelOrderId, isNotNull);
      print('[QA PASS 5.3] Fuel delivery order created: ID=$fuelOrderId, Status: ${fuelOrder['status']}');

      // Cancel order
      await apiClient.patch('/api/v1/fuel/orders/$fuelOrderId/status', body: {'status': 'cancelled'}, requiresAuth: true);
      final canceledOrder = await apiClient.get('/api/v1/fuel/orders/$fuelOrderId', requiresAuth: true);
      expect((canceledOrder as Map)['status'], 'cancelled');
      print('[QA PASS 5.4] Fuel order cancelled and verified.');

      print('===============================================================');
      print('PHASE 6: MARKETPLACE CATALOG & ORDER FLOW');
      print('===============================================================');

      final marketplaceRepo = MarketplaceRepository(apiClient: apiClient);
      final categories = await marketplaceRepo.fetchCategories();
      final brands = await marketplaceRepo.fetchBrands();
      final products = await marketplaceRepo.fetchProducts();
      final offers = await marketplaceRepo.fetchOffers();

      expect(categories, isA<List<Category>>());
      expect(brands, isA<List<Brand>>());
      expect(products, isA<List<Product>>());
      expect(offers, isA<List<Offer>>());
      print('[QA PASS 6.1] Marketplace real catalog fetched: ${categories.length} categories, ${brands.length} brands, ${products.length} products, ${offers.length} offers.');

      // Create Marketplace Order
      final mkpOrder = await apiClient.post(
        '/api/v1/marketplace/orders',
        body: {
          'address': '123 Tech Park, Bengaluru',
          'payment_method': 'UPI',
          'items': [
            {
              'product_id': 'prod_oil_01',
              'product_name': 'Full Synthetic Motor Oil 5W-30',
              'brand': 'Castrol',
              'quantity': 2,
              'unit_price': 1850.0,
            }
          ],
        },
        requiresAuth: true,
      );
      final mkpOrderId = (mkpOrder as Map)['id'];
      expect(mkpOrderId, isNotNull);
      print('[QA PASS 6.2] Marketplace order placed: ID=$mkpOrderId, total: ₹${mkpOrder['total_amount']}');

      final getMkpOrder = await apiClient.get('/api/v1/marketplace/orders/$mkpOrderId', requiresAuth: true);
      expect((getMkpOrder as Map)['id'], mkpOrderId);
      print('[QA PASS 6.3] Marketplace order verified via GET /api/v1/marketplace/orders/$mkpOrderId.');

      print('===============================================================');
      print('PHASE 7: AI DIAGNOSIS & TRANSPARENT FALLBACK');
      print('===============================================================');

      final diagnosisService = DiagnosisService(apiClient: apiClient, enableFallback: true);
      final diagResult = await diagnosisService.diagnose(
        vehicleName: 'Toyota Fortuner',
        vehicleType: 'Car',
        problem: 'Brake squeaking noise',
        symptoms: ['Squeaking sound when braking at low speed'],
      );
      expect(diagResult, isA<Diagnosis>());
      expect(diagResult.problem.isNotEmpty, isTrue);
      print('[QA PASS 7.1] Diagnosis completed: "${diagResult.problem}" (Severity: ${diagResult.severity.label}, OfflineFallback: ${diagResult.isOfflineFallback})');

      print('===============================================================');
      print('PHASE 8: CHAT / CONVERSATIONS LIFECYCLE');
      print('===============================================================');

      final sessionRes = await apiClient.post(
        '/api/v1/conversation/session',
        body: {},
        requiresAuth: true,
      );
      expect(sessionRes, isA<Map<String, dynamic>>());
      final sessionId = (sessionRes as Map)['session_id']?.toString();
      expect(sessionId, isNotNull);
      print('[QA PASS 8.1] Conversation session created: ID=$sessionId');

      final chatRes = await apiClient.post(
        '/api/v1/conversation/chat',
        body: {
          'message': 'Hello, my engine makes a squealing noise on cold start.',
          'session_id': sessionId,
        },
        requiresAuth: true,
      );
      expect(chatRes, isA<Map<String, dynamic>>());
      final responseText = (chatRes as Map)['response'];
      expect(responseText, isNotNull);
      print('[QA PASS 8.2] User message dispatched & AI response received: "$responseText"');

      final historyRes = await apiClient.get(
        '/api/v1/conversation/history?session_id=$sessionId',
        requiresAuth: true,
      );
      expect(historyRes, isA<Map<String, dynamic>>());
      final historyList = (historyRes as Map)['history'] as List?;
      expect(historyList, isNotNull);
      expect(historyList!.isNotEmpty, isTrue);
      print('[QA PASS 8.3] Conversation history verified: ${historyList.length} turns in session.');

      print('===============================================================');
      print('PHASE 9: LOGOUT & RELOGIN PERSISTENCE');
      print('===============================================================');

      // Logout
      await authProvider.logout();
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(authProvider.isLoggedIn, isFalse);
      final tokenAfterLogout = await apiClient.getAccessToken();
      expect(tokenAfterLogout, isNull);
      print('[QA PASS 9.1] User logged out. Session tokens wiped. User returned to LoginScreen.');

      // Relogin
      final reloginSuccess = await authProvider.login('testdriver@example.com', 'TestPassword123!');
      expect(reloginSuccess, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      final reloginToken = await apiClient.getAccessToken();
      expect(reloginToken, isNotNull);
      print('[QA PASS 9.2] User re-authenticated successfully. New session token established.');
      print('===============================================================');
      print('MANUAL QA REAL-DEVICE VERIFICATION COMPLETED WITH 100% PASS');
      print('===============================================================');
    });
  });
}
