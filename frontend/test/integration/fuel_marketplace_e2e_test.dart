import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mecha_connect/features/fuel_delivery/models/models.dart';
import 'package:mecha_connect/features/fuel_delivery/repositories/fuel_repository.dart';
import 'package:mecha_connect/features/marketplace/repositories/marketplace_repository.dart';
import 'package:mecha_connect/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();

  const String baseUrl = 'http://127.0.0.1:8000';
  bool isServerAvailable = false;

  setUpAll(() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        isServerAvailable = true;
      }
    } catch (_) {
      isServerAvailable = false;
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('End-to-End Flutter -> Real FastAPI Server Integration', () {
    test('1. Backend health check returns 200 OK and database ok', () async {
      if (!isServerAvailable) return;
      final response = await http.get(Uri.parse('$baseUrl/health'));
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['status'], 'healthy');
      expect(body['database'], 'ok');
    });

    test('2. Public Fuel endpoints respond via ApiClient', () async {
      if (!isServerAvailable) return;
      final apiClient = ApiClient(baseUrl: baseUrl);

      // GET /api/v1/fuel/stations
      final stationsRes = await apiClient.get('/api/v1/fuel/stations', requiresAuth: false);
      expect(stationsRes, isA<List>());

      // POST /api/v1/fuel/estimate
      final estimateRes = await apiClient.post(
        '/api/v1/fuel/estimate',
        body: {'fuel_type': 'petrol', 'quantity': 10.0},
        requiresAuth: false,
      );
      expect(estimateRes, isA<Map<String, dynamic>>());
      final estimate = PriceEstimate.fromJson(estimateRes as Map<String, dynamic>);
      expect(estimate.grandTotal, greaterThan(0));
      expect(estimate.fuelCost, 1025.0);
    });

    test('3. Public Marketplace endpoints respond via ApiClient', () async {
      if (!isServerAvailable) return;
      final apiClient = ApiClient(baseUrl: baseUrl);

      // Categories
      final catsRes = await apiClient.get('/api/v1/marketplace/categories', requiresAuth: false);
      expect(catsRes, isA<List>());

      // Brands
      final brandsRes = await apiClient.get('/api/v1/marketplace/brands', requiresAuth: false);
      expect(brandsRes, isA<List>());

      // Offers
      final offersRes = await apiClient.get('/api/v1/marketplace/offers', requiresAuth: false);
      expect(offersRes, isA<List>());

      // Products
      final prodsRes = await apiClient.get('/api/v1/marketplace/products', requiresAuth: false);
      expect(prodsRes, isA<List>());

      // Coupon validate
      final couponRes = await apiClient.post(
        '/api/v1/marketplace/coupons/validate',
        body: {'code': 'SAVE10', 'order_amount': 1500.0},
        requiresAuth: false,
      );
      expect(couponRes, isA<Map<String, dynamic>>());
      expect(couponRes['is_valid'], isFalse); // clean empty DB
    });

    test('4. Protected endpoints reject unauthenticated or invalid JWT requests', () async {
      if (!isServerAvailable) return;
      final apiClient = ApiClient(baseUrl: baseUrl);
      await apiClient.clearTokens();

      // No token -> 401
      expect(
        () async => await apiClient.get('/api/v1/fuel/orders', requiresAuth: true),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      // Invalid token -> 401
      await apiClient.saveTokens(accessToken: 'invalid.jwt.token', refreshToken: 'invalid.refresh.token');
      expect(
        () async => await apiClient.get('/api/v1/fuel/orders', requiresAuth: true),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      // Clean up
      await apiClient.clearTokens();
    });

    test('5. FuelRepository and MarketplaceRepository execute cleanly over real HTTP client', () async {
      if (!isServerAvailable) return;
      final apiClient = ApiClient(baseUrl: baseUrl);
      final fuelRepo = FuelRepository(apiClient: apiClient);
      final marketplaceRepo = MarketplaceRepository(apiClient: apiClient);

      final stations = await fuelRepo.getFuelStations(latitude: 12.97, longitude: 77.59);
      expect(stations.isNotEmpty, isTrue);

      final products = await marketplaceRepo.fetchProducts();
      expect(products.isNotEmpty, isTrue);

      final categories = await marketplaceRepo.fetchCategories();
      expect(categories.isNotEmpty, isTrue);

      final brands = await marketplaceRepo.fetchBrands();
      expect(brands.isNotEmpty, isTrue);
    });
  });
}
