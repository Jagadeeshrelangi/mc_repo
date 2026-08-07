import '../models/models.dart';

/// Mock Marketplace API.
///
/// Sprint 1.8 serves a static in-memory catalog with a simulated 700ms network
/// latency so the UI behaves exactly like production. Sprint 2 swaps the
/// internals for the real backend client — the provider and screens never
/// change because they depend only on this interface.
class MarketplaceRepository {
  static const Duration _latency = Duration(milliseconds: 700);

  int _orderCounter = 0;

  Future<void> _delay() => Future<void>.delayed(_latency);

  // ── Catalog ───────────────────────────────────────────────────────────

  Future<List<Product>> fetchProducts() async {
    await _delay();
    return kMarketplaceProducts;
  }

  Future<List<Category>> fetchCategories() async {
    await _delay();
    return kMarketplaceCategories;
  }

  Future<List<Brand>> fetchBrands() async {
    await _delay();
    return kMarketplaceBrands;
  }

  Future<List<Offer>> fetchOffers() async {
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
  }) async {
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
