import 'package:flutter/foundation.dart' hide Category;
import 'package:mecha_connect/services/api_client.dart';
import '../models/models.dart';

/// Marketplace API repository connecting Flutter with FastAPI `/api/v1/marketplace/*`.
class MarketplaceRepository {
  static const Duration _latency = Duration(milliseconds: 700);

  final ApiClient? _apiClient;
  int _orderCounter = 0;

  MarketplaceRepository({ApiClient? apiClient}) : _apiClient = apiClient;

  Future<void> _delay() => Future<void>.delayed(_latency);

  // ── Catalog ───────────────────────────────────────────────────────────

  Future<List<Product>> fetchProducts() async {
    final client = _apiClient;
    if (client != null) {
      try {
        final res = await client.get('/api/v1/marketplace/products', requiresAuth: false);
        if (res is List && res.isNotEmpty) {
          return res.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        debugPrint('Backend product fetch fell back to simulated: $e');
      }
    }
    await _delay();
    return kMarketplaceProducts;
  }

  Future<List<Category>> fetchCategories() async {
    final client = _apiClient;
    if (client != null) {
      try {
        final res = await client.get('/api/v1/marketplace/categories', requiresAuth: false);
        if (res is List && res.isNotEmpty) {
          return res.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        debugPrint('Backend category fetch fell back to simulated: $e');
      }
    }
    await _delay();
    return kMarketplaceCategories;
  }

  Future<List<Brand>> fetchBrands() async {
    final client = _apiClient;
    if (client != null) {
      try {
        final res = await client.get('/api/v1/marketplace/brands', requiresAuth: false);
        if (res is List && res.isNotEmpty) {
          return res.map((json) => Brand.fromJson(json as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        debugPrint('Backend brand fetch fell back to simulated: $e');
      }
    }
    await _delay();
    return kMarketplaceBrands;
  }

  Future<List<Offer>> fetchOffers() async {
    final client = _apiClient;
    if (client != null) {
      try {
        final res = await client.get('/api/v1/marketplace/offers', requiresAuth: false);
        if (res is List && res.isNotEmpty) {
          final List<Offer> mappedOffers = res.map((json) {
            final offer = Offer.fromJson(json as Map<String, dynamic>);
            return offer;
          }).toList();
          return mappedOffers;
        }
      } catch (e) {
        debugPrint('Backend offers fetch fell back to simulated: $e');
      }
    }
    await _delay();
    return kMarketplaceOffers;
  }

  /// Coupons are part of the catalog (mock). Sprint 2 validates them on the
  /// server; the provider still calls this same method.
  List<Coupon> getCoupons() => kMarketplaceCoupons;

  // ── Orders ────────────────────────────────────────────────────────────

  /// Creates one marketplace order per cart line. The Orders tab is written by
  /// the provider via `parts/order_data.dart` (shared store), while these typed
  /// records power the checkout confirmation flow.
  Future<List<MarketplaceOrder>> createOrder({
    required List<OrderItem> items,
    required String address,
    required String paymentMethod,
    String? couponCode,
  }) async {
    final client = _apiClient;
    if (client != null) {
      try {
        final payload = {
          'address': address,
          'payment_method': paymentMethod,
          'items': items.map((i) => {
            'product_id': i.productId,
            'product_name': i.name,
            'brand': i.brand,
            'quantity': i.quantity,
            'unit_price': i.unitPrice,
            'image': i.imageUrl,
          }).toList(),
        };
        final queryParam = couponCode != null && couponCode.isNotEmpty
            ? '?coupon_code=$couponCode'
            : '';
        final res = await client.post(
          '/api/v1/marketplace/orders$queryParam',
          body: payload,
          requiresAuth: true,
        );
        if (res is Map<String, dynamic>) {
          final orderId = (res['external_id'] ?? res['id'] ?? '').toString();
          final createdAt = res['created_at'] != null
              ? DateTime.tryParse(res['created_at'].toString()) ?? DateTime.now()
              : DateTime.now();
          return items.map((item) {
            _orderCounter++;
            return MarketplaceOrder(
              id: orderId.isNotEmpty ? orderId : 'MKP-${createdAt.year}-${_orderCounter.toString().padLeft(4, '0')}',
              item: item,
              address: address,
              paymentMethod: paymentMethod,
              total: item.lineTotal,
              createdAt: createdAt,
            );
          }).toList();
        }
      } catch (e) {
        debugPrint('Backend marketplace order creation fell back: $e');
        if (e is ApiException) rethrow;
      }
    }

    await _delay();
    final now = DateTime.now();
    return items.map((item) {
      _orderCounter++;
      final id =
          'MKP-${now.year}-${_orderCounter.toString().padLeft(4, '0')}';
      return MarketplaceOrder(
        id: id,
        item: item,
        address: address,
        paymentMethod: paymentMethod,
        total: item.lineTotal,
        createdAt: now,
      );
    }).toList();
  }
}
