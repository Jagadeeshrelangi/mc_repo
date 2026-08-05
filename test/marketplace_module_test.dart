import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mecha_connect/features/marketplace/models/models.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/features/marketplace/repositories/marketplace_repository.dart';
import 'package:mecha_connect/features/marketplace/screens/cart_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/category_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/checkout_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/marketplace_home_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/order_success_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/product_detail_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/search_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/wishlist_screen.dart';
import 'package:mecha_connect/features/marketplace/services/cart_service.dart';
import 'package:mecha_connect/features/marketplace/utils/currency_formatter.dart';
import 'package:mecha_connect/features/marketplace/widgets/cart_item_tile.dart';
import 'package:mecha_connect/features/marketplace/widgets/marketplace_shimmer.dart';
import 'package:mecha_connect/features/home/providers/home_provider.dart';
import 'package:mecha_connect/features/home/repositories/home_repository.dart';
import 'package:mecha_connect/features/home/screens/home_screen.dart';
import 'package:mecha_connect/parts/order_data.dart';
import 'package:mecha_connect/services/geocoding_service.dart';
import 'package:mecha_connect/services/location_provider.dart';
import 'package:mecha_connect/widgets/location_status_banner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Product get _sparkPlug => kMarketplaceProducts.firstWhere((p) => p.id == 'p-spark-plug');
Product get _chainKit => kMarketplaceProducts.firstWhere((p) => p.id == 'p-chain-kit');
Product get _obd => kMarketplaceProducts.firstWhere((p) => p.id == 'p-out-of-stock');

/// LocationProvider whose permission/GPS methods are inert but report a
/// resolved location, so GPS-first screens (checkout address sheet) resolve to
/// a success prefill without touching platform channels or the network.
class _FakeLocationProvider extends LocationProvider {
  @override
  bool get hasLocation => true;

  @override
  LatLng? get currentLatLng => const LatLng(12.9716, 77.5946);

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
  LocationPermissionState get permissionState => LocationPermissionState.granted;

  @override
  Future<void> checkAndRequestPermission() async {}

  @override
  Future<bool> getCurrentLocation() async => true;
}

/// LocationProvider whose permission is denied — checkout's GPS-first sheet
/// must fall back to manual entry instead of hanging or succeeding empty.
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

/// Pumps [child] with an explicit [LocationProvider] instance (for denied /
/// error detection states).
Widget _wrapWithLocation(
    Widget child, MarketplaceProvider provider, LocationProvider location) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MarketplaceProvider>.value(value: provider),
      ChangeNotifierProvider<LocationProvider>.value(value: location),
    ],
    child: MaterialApp(home: child),
  );
}

/// Pumps [child] under a shared MarketplaceProvider instance plus the shared
/// LocationProvider (needed by every GPS-first address screen).
Widget _wrap(Widget child, MarketplaceProvider provider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MarketplaceProvider>.value(value: provider),
      ChangeNotifierProvider<LocationProvider>(
        create: (_) => _FakeLocationProvider(),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

/// Pumps [child] with an explicit light/dark [MaterialApp] theme.
Widget _wrapThemed(Widget child, MarketplaceProvider provider,
    {bool dark = false}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MarketplaceProvider>.value(value: provider),
      ChangeNotifierProvider<LocationProvider>(
        create: (_) => _FakeLocationProvider(),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: child,
    ),
  );
}

/// Loads the catalog and flushes the 700ms simulated latency.
Future<void> _preload(MarketplaceProvider provider, WidgetTester tester) async {
  provider.load();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump(const Duration(milliseconds: 800));
}

/// Flushes a navigation push/pop (build frame + transition).
Future<void> _navSettle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

/// Marketplace repository whose catalog fetches start succeeding and can be
/// flipped to failing — used to prove a failed refresh keeps loaded content.
class _FlakyRepository extends MarketplaceRepository {
  bool fail = false;

  Future<T> _maybe<T>(T value) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (fail) throw Exception('simulated network failure');
    return value;
  }

  @override
  Future<List<Product>> fetchProducts() => _maybe(kMarketplaceProducts);

  @override
  Future<List<Category>> fetchCategories() => _maybe(kMarketplaceCategories);

  @override
  Future<List<Brand>> fetchBrands() => _maybe(kMarketplaceBrands);

  @override
  Future<List<Offer>> fetchOffers() => _maybe(kMarketplaceOffers);
}

void main() {
  setUp(() {
    resetOrdersList();
    SharedPreferences.setMockInitialValues({});
  });

  group('formatINR', () {
    test('formats with Indian digit grouping', () {
      expect(formatINR(999), '₹999');
      expect(formatINR(1000), '₹1,000');
      expect(formatINR(3499), '₹3,499');
      expect(formatINR(123456), '₹1,23,456');
    });

    test('rounds decimals by default', () {
      expect(formatINR(549.5), '₹550');
      expect(formatINR(699.4), '₹699');
    });
  });

  group('CartService', () {
    test('empty cart produces a zero summary', () {
      final s = CartService().calculate(const []);
      expect(s.itemsTotal, 0);
      expect(s.gst, 0);
      expect(s.deliveryFee, 0);
      expect(s.couponDiscount, 0);
      expect(s.grandTotal, 0);
    });

    test('adds GST and delivery fee below the free threshold', () {
      final s = CartService().calculate([
        CartItem(product: _sparkPlug, quantity: 1),
      ]);
      expect(s.itemsTotal, closeTo(549, 0.001));
      expect(s.gst, closeTo(98.82, 0.001));
      expect(s.deliveryFee, 49);
      expect(s.grandTotal, closeTo(696.82, 0.001));
      expect(s.savings, closeTo(699 - 549, 0.001));
    });

    test('waives delivery above the free threshold', () {
      final s = CartService().calculate([
        CartItem(product: _sparkPlug, quantity: 2),
      ]);
      expect(s.itemsTotal, closeTo(1098, 0.001));
      expect(s.deliveryFee, 0);
    });

    test('applies a capped percentage coupon', () {
      final coupon = kMarketplaceCoupons.firstWhere((c) => c.code == 'MECHA10');
      final s = CartService().calculate(
        [CartItem(product: _sparkPlug, quantity: 1)],
        coupon: coupon,
      );
      expect(s.couponDiscount, closeTo(54.9, 0.001));
      expect(s.grandTotal, closeTo(641.92, 0.001));
    });

    test('applies a free-delivery coupon', () {
      final coupon = kMarketplaceCoupons.firstWhere((c) => c.code == 'FREESHIP');
      final s = CartService().calculate(
        [CartItem(product: _sparkPlug, quantity: 1)],
        coupon: coupon,
      );
      expect(s.deliveryFee, 0);
    });

    test('applies a flat coupon', () {
      const coupon = Coupon(
        id: 'flat',
        code: 'FLAT100',
        title: '',
        description: '',
        type: CouponType.flat,
        value: 100,
      );
      final s = CartService().calculate(
        [CartItem(product: _sparkPlug, quantity: 1)],
        coupon: coupon,
      );
      expect(s.couponDiscount, closeTo(100, 0.001));
    });
  });

  group('MarketplaceProvider', () {
    test('loads the full catalog and reaches ready', () async {
      final provider = MarketplaceProvider();
      expect(provider.state, MarketplaceScreenState.initial);
      await provider.load();
      expect(provider.state, MarketplaceScreenState.ready);
      expect(provider.products.length, greaterThanOrEqualTo(30));
      expect(provider.categories.length, 10);
      expect(provider.brands.length, 15);
      expect(provider.offers.length, 3);
      expect(provider.coupons, hasLength(3));
    });

    test('search filters the visible list', () async {
      final provider = MarketplaceProvider();
      await provider.load();
      provider.setSearchQuery('ngk');
      expect(provider.visibleProducts, isNotEmpty);
      for (final p in provider.visibleProducts) {
        expect(p.name.toLowerCase(), contains('ngk'));
      }
      provider.setSearchQuery('');
      expect(provider.visibleProducts.length, provider.products.length);
    });

    test('brand + price + in-stock + rating + vehicle filters compose', () async {
      final provider = MarketplaceProvider();
      await provider.load();

      provider.toggleBrand('rolon');
      expect(provider.visibleProducts, isNotEmpty);
      for (final p in provider.visibleProducts) {
        expect(p.brandId, 'rolon');
      }

      provider.resetFilters();
      provider.setPriceRange(null, 500);
      expect(provider.visibleProducts, isNotEmpty);
      for (final p in provider.visibleProducts) {
        expect(p.price, lessThanOrEqualTo(500));
      }

      provider.resetFilters();
      provider.toggleInStockOnly();
      expect(provider.visibleProducts.every((p) => p.inStock), isTrue);
      expect(provider.visibleProducts.any((p) => p.id == _obd.id), isFalse);

      provider.resetFilters();
      provider.setMinRating(4.5);
      expect(provider.visibleProducts, isNotEmpty);
      for (final p in provider.visibleProducts) {
        expect(p.rating, greaterThanOrEqualTo(4.5));
      }

      provider.resetFilters();
      provider.setVehicleTypes({VehicleType.suv});
      expect(provider.visibleProducts, isNotEmpty);
      for (final p in provider.visibleProducts) {
        expect(p.vehicleTypes, contains(VehicleType.suv));
      }

      provider.setVehicleTypes({VehicleType.truck});
      expect(provider.visibleProducts, isEmpty);
    });

    test('sort options order the visible list', () async {
      final provider = MarketplaceProvider();
      await provider.load();

      provider.setSortOption(SortOption.priceLowToHigh);
      var prices = provider.visibleProducts.map((p) => p.price).toList();
      for (var i = 1; i < prices.length; i++) {
        expect(prices[i], greaterThanOrEqualTo(prices[i - 1]));
      }

      provider.setSortOption(SortOption.priceHighToLow);
      prices = provider.visibleProducts.map((p) => p.price).toList();
      for (var i = 1; i < prices.length; i++) {
        expect(prices[i], lessThanOrEqualTo(prices[i - 1]));
      }

      provider.setSortOption(SortOption.bestRated);
      final ratings = provider.visibleProducts.map((p) => p.rating).toList();
      for (var i = 1; i < ratings.length; i++) {
        expect(ratings[i], lessThanOrEqualTo(ratings[i - 1]));
      }
    });

    test('addToCart merges quantities and clamps to stock', () async {
      final provider = MarketplaceProvider();
      await provider.load();
      provider.addToCart(_sparkPlug, quantity: 2);
      provider.addToCart(_sparkPlug, quantity: 1);
      expect(provider.cartCount, 3);
      provider.setQuantity(_sparkPlug.id, 99);
      expect(provider.quantityInCart(_sparkPlug.id), _sparkPlug.stock);
      provider.setQuantity(_sparkPlug.id, 0);
      expect(provider.quantityInCart(_sparkPlug.id), 1);
      provider.decrementQuantity(_sparkPlug.id);
      expect(provider.cart, isEmpty);
    });

    test('coupons apply only above the minimum order value', () async {
      final provider = MarketplaceProvider();
      await provider.load();
      expect(provider.applyCoupon('MECHA20'), isFalse); // min ₹1,499
      expect(provider.appliedCoupon, isNull);

      provider.addToCart(_sparkPlug, quantity: 3); // ₹1,647
      expect(provider.applyCoupon('MECHA20'), isTrue);
      expect(provider.appliedCoupon!.code, 'MECHA20');
      expect(provider.priceSummary.couponDiscount, closeTo(329.4, 0.001));

      provider.removeCoupon();
      expect(provider.appliedCoupon, isNull);
    });

    test('wishlist toggle, remove and move-to-cart', () async {
      final provider = MarketplaceProvider();
      await provider.load();
      expect(provider.isWishlisted(_sparkPlug.id), isFalse);
      provider.toggleWishlist(_sparkPlug);
      expect(provider.isWishlisted(_sparkPlug.id), isTrue);
      provider.toggleWishlist(_sparkPlug);
      expect(provider.wishlist, isEmpty);

      provider.toggleWishlist(_sparkPlug);
      provider.moveWishlistToCart(_sparkPlug.id);
      expect(provider.wishlist, isEmpty);
      expect(provider.cartCount, 1);
    });

    test('openProduct records recently viewed', () async {
      final provider = MarketplaceProvider();
      await provider.load();
      provider.openProduct(_sparkPlug);
      provider.openProduct(_chainKit);
      expect(provider.recentlyViewed.map((p) => p.id).toList(),
          ['p-chain-kit', 'p-spark-plug']);
    });

    test('placeOrder writes the Orders tab store and clears the cart', () async {
      final provider = MarketplaceProvider();
      await provider.load();
      provider.addToCart(_sparkPlug, quantity: 2);
      provider.addToCart(_chainKit, quantity: 1);
      final totalBefore = provider.priceSummary.grandTotal;

      final ok = await provider.placeOrder(
        address: const CheckoutAddress(
          name: 'Ravi Kumar',
          phone: '9876543210',
          address: '12 MG Road',
          city: 'Bengaluru',
          state: 'Karnataka',
          pincode: '560001',
        ),
        paymentMethod: 'UPI',
      );

      expect(ok, isTrue);
      expect(provider.cart, isEmpty);
      expect(provider.lastOrderIds, hasLength(2));
      expect(provider.lastOrderTotal, closeTo(totalBefore, 0.001));

      final first = ordersList.first;
      expect(first['id'], startsWith('MKP-'));
      expect(first['type'], 'parts');
      expect(ordersList.length, greaterThanOrEqualTo(7));
      expect(ordersList.where((o) => o['id'] == provider.lastOrderIds.first),
          hasLength(1));
    });
  });

  group('Home screen', () {
    testWidgets('shows skeleton while loading then the full page', (tester) async {
      final provider = MarketplaceProvider();
      await tester.pumpWidget(_wrap(const MarketplaceHomeScreen(), provider));

      expect(find.byType(ShimmerBox), findsWidgets);

      await _preload(provider, tester);

      expect(find.byType(ShimmerBox), findsNothing);
      expect(find.text('Marketplace'), findsOneWidget);
      expect(find.text('Search parts, oils, tyres...'), findsOneWidget);
      expect(find.text('Browse All Products'), findsOneWidget);
    });

    testWidgets('boots the catalog itself without an external load() call',
        (tester) async {
      final provider = MarketplaceProvider();
      await tester.pumpWidget(_wrap(const MarketplaceHomeScreen(), provider));

      expect(provider.state, isNot(MarketplaceScreenState.ready));

      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));

      expect(provider.state, MarketplaceScreenState.ready);
      expect(find.byType(ShimmerBox), findsNothing);
      expect(find.text('Browse All Products'), findsOneWidget);
    });

    testWidgets('search entry opens the search screen', (tester) async {
      final provider = MarketplaceProvider();
      await tester.pumpWidget(_wrap(const MarketplaceHomeScreen(), provider));
      await _preload(provider, tester);

      await tester.tap(find.text('Search parts, oils, tyres...'));
      await _navSettle(tester);

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
    });

    testWidgets('home renders without overflow at 320/360/412dp', (tester) async {
      for (final width in [320.0, 360.0, 412.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final provider = MarketplaceProvider();
        await tester.pumpWidget(_wrap(const MarketplaceHomeScreen(), provider));
        await _preload(provider, tester);

        expect(tester.takeException(), isNull,
            reason: 'overflow at ${width}dp');
      }
    });
  });

  group('Search screen', () {
    testWidgets('typing filters results live', (tester) async {
      final provider = MarketplaceProvider();
      await tester.pumpWidget(_wrap(const SearchScreen(), provider));
      await _preload(provider, tester);

      await tester.enterText(find.byType(TextField), 'ngk');
      await tester.pump();

      final results = provider.visibleProducts;
      expect(results, isNotEmpty);
      expect(find.textContaining('results for "ngk"'), findsOneWidget);
      expect(find.text('NGK Iridium Spark Plug'), findsWidgets);
    });
  });

  group('Product detail', () {
    testWidgets('add to cart updates provider and shows feedback', (tester) async {
      final provider = MarketplaceProvider();
      provider.load();
      await tester.pumpWidget(_wrap(const SearchScreen(), provider));
      await _preload(provider, tester);

      provider.setSearchQuery('ngk');
      await tester.pump();
      await tester.tap(find.text('NGK Iridium Spark Plug').first);
      await _navSettle(tester);

      expect(find.text('Add to Cart'), findsOneWidget);
      await tester.tap(find.text('Add to Cart'));
      await tester.pump();
      expect(provider.cartCount, 1);
      expect(find.text('NGK Iridium Spark Plug added to cart'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('Cart & Checkout', () {
    testWidgets('empty cart shows the empty state', (tester) async {
      final provider = MarketplaceProvider();
      await tester.pumpWidget(_wrap(const CartScreen(), provider));
      expect(find.text('Your cart is empty'), findsOneWidget);
    });

    testWidgets('full checkout flow registers an order in the Orders tab',
        (tester) async {
      final provider = MarketplaceProvider();
      await tester.pumpWidget(_wrap(const CartScreen(), provider));
      await _preload(provider, tester);

      provider.addToCart(_sparkPlug, quantity: 2);
      await tester.pump();
      expect(find.text('NGK Iridium Spark Plug'), findsWidgets);
      expect(find.textContaining('Proceed to Checkout'), findsOneWidget);

      await tester.tap(find.textContaining('Proceed to Checkout'));
      await _navSettle(tester);
      expect(find.byType(CheckoutScreen), findsOneWidget);

      await tester.tap(find.text('Add delivery address'));
      await _navSettle(tester);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full name'), 'Ravi Kumar');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone'), '9876543210');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Address'), '12 MG Road');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'PIN code'), '560001');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'City'), 'Bengaluru');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'State'), 'Karnataka');
      await tester.tap(find.text('Continue'));
      await _navSettle(tester);

      expect(find.textContaining('Ravi Kumar'), findsWidgets);

      await tester.tap(find.textContaining('Place Order'));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));
      await _navSettle(tester);

      expect(find.byType(OrderSuccessScreen), findsOneWidget);
      expect(find.text('Order Placed!'), findsOneWidget);
      expect(provider.cart, isEmpty);
      expect(ordersList.first['id'], startsWith('MKP-'));
      expect(ordersList.first['type'], 'parts');
    });

    testWidgets('cart badge, cart body and checkout total share one source',
        (tester) async {
      final provider = MarketplaceProvider();
      await tester.pumpWidget(_wrap(const CartScreen(), provider));
      await _preload(provider, tester);

      provider.addToCart(_sparkPlug, quantity: 2);
      provider.addToCart(_chainKit, quantity: 1);
      await tester.pump();

      final cartTotal = provider.priceSummary.grandTotal;
      expect(provider.cartCount, 3);
      expect(find.text('Cart (3)'), findsOneWidget);
      expect(find.byType(CartItemTile), findsNWidgets(2));
      expect(find.text('Proceed to Checkout  •  ₹${cartTotal.round()}'),
          findsOneWidget,
          reason: 'cart total must derive from the same provider summary');

      await tester.tap(find.textContaining('Proceed to Checkout'));
      await _navSettle(tester);
      expect(find.byType(CheckoutScreen), findsOneWidget);

      // Checkout reads the SAME single provider — the order button total
      // cannot diverge from the badge or the cart summary.
      expect(find.text('Place Order  •  ₹${cartTotal.round()}'), findsOneWidget,
          reason: 'checkout total must equal the cart grand total');
      expect(find.text('Cart (3)'), findsNothing);
    });

    testWidgets(
        'checkout address sheet auto-detects GPS and prefills editable fields',
        (tester) async {
      final provider = MarketplaceProvider();
      await tester.pumpWidget(_wrap(const CheckoutScreen(), provider));
      await _preload(provider, tester);

      provider.addToCart(_sparkPlug, quantity: 1);
      await tester.pump();

      await tester.tap(find.text('Add delivery address'));
      await _navSettle(tester);

      // GPS-first: the shared banner reports success and the shared location
      // pipeline prefilled the address/pincode/city/state fields.
      expect(find.byType(LocationStatusBanner), findsOneWidget);
      expect(find.text('📍 Current Location Detected'), findsOneWidget);

      final addressField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Address'));
      final pincodeField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'PIN code'));
      final cityField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'City'));
      final stateField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'State'));
      expect(addressField.controller!.text, 'MG Road');
      expect(pincodeField.controller!.text, '560001');
      expect(cityField.controller!.text, 'Bengaluru');
      expect(stateField.controller!.text, 'Karnataka');
      // GPS is a prefill, never a lock-in — every field stays editable.
      expect(addressField.enabled, isTrue);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full name'), 'Ravi Kumar');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone'), '9876543210');
      await tester.tap(find.text('Continue'));
      await _navSettle(tester);

      expect(find.textContaining('Ravi Kumar'), findsWidgets);
    });

    testWidgets('checkout address sheet denied permission offers manual entry',
        (tester) async {
      final provider = MarketplaceProvider();
      final location = _DeniedLocationProvider();
      await tester.pumpWidget(
          _wrapWithLocation(const CheckoutScreen(), provider, location));
      await _preload(provider, tester);

      provider.addToCart(_sparkPlug, quantity: 1);
      await tester.pump();

      await tester.tap(find.text('Add delivery address'));
      await _navSettle(tester);

      expect(find.text('Location permission denied.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Enter Manually'), findsOneWidget);

      await tester.tap(find.text('Enter Manually'));
      await tester.pump();
      expect(find.text('Location permission denied.'), findsNothing);
      expect(find.text('Use Current Location'), findsOneWidget);
      expect(
          tester
              .widget<TextFormField>(
                  find.widgetWithText(TextFormField, 'Address'))
              .enabled,
          isTrue);
    });

    testWidgets(
        'address sheet renders without overflow in light/dark at 320/390/412dp',
        (tester) async {
      for (final width in [320.0, 390.0, 412.0]) {
        for (final dark in [false, true]) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final provider = MarketplaceProvider();
          await tester.pumpWidget(
              _wrapThemed(const CheckoutScreen(), provider, dark: dark));
          await _preload(provider, tester);

          provider.addToCart(_sparkPlug, quantity: 1);
          await tester.pump();

          await tester.tap(find.text('Add delivery address'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));

          expect(tester.takeException(), isNull,
              reason: 'address sheet ${width}dp dark=$dark');
          expect(find.byType(LocationStatusBanner), findsOneWidget);

          // Reset the tree so the open modal sheet (and its barrier) does not
          // leak into the next iteration — pumpWidget preserves the Navigator's
          // route stack across same-runtimeType roots.
          await tester.pumpWidget(const SizedBox());
        }
      }
    });
  });

  group('Wishlist', () {
    testWidgets('move to cart adds the item and clears the list', (tester) async {
      final provider = MarketplaceProvider();
      await tester.pumpWidget(_wrap(const WishlistScreen(), provider));
      await _preload(provider, tester);

      expect(find.text('Nothing saved yet'), findsOneWidget);

      provider.toggleWishlist(_sparkPlug);
      await tester.pump();
      expect(find.text('NGK Iridium Spark Plug'), findsOneWidget);

      await tester.tap(find.text('Move to Cart'));
      await tester.pump();
      expect(provider.cartCount, 1);
      expect(provider.wishlist, isEmpty);
      expect(find.text('Nothing saved yet'), findsOneWidget);
    });
  });

  group('Repository', () {
    test('creates one order per cart line with unique ids', () async {
      final repo = MarketplaceRepository();
      final orders = await repo.createOrder(
        items: [
          OrderItem(
              productId: 'a', name: 'A', brand: 'B', imageUrl: null,
              unitPrice: 10, quantity: 1),
          OrderItem(
              productId: 'c', name: 'C', brand: 'D', imageUrl: null,
              unitPrice: 20, quantity: 2),
        ],
        address: 'addr',
        paymentMethod: 'UPI',
      );
      expect(orders, hasLength(2));
      expect(orders[0].id, isNot(orders[1].id));
      expect(orders[0].total, 10);
      expect(orders[1].total, 40);
    });
  });

  group('Runtime stabilization (Sprint 1.8.1)', () {
    testWidgets('pull-to-refresh keeps the home page (no skeleton flash)',
        (tester) async {
      final provider = MarketplaceProvider();
      await tester.pumpWidget(_wrap(const MarketplaceHomeScreen(), provider));
      await _preload(provider, tester);
      expect(provider.state, MarketplaceScreenState.ready);
      expect(find.byType(ShimmerBox), findsNothing);

      final refresh = provider.refresh();
      await tester.pump();
      expect(provider.isRefreshing, isTrue);
      expect(provider.state, MarketplaceScreenState.ready,
          reason: 'refresh must not flip the page back into loading');
      expect(find.byType(ShimmerBox), findsNothing);
      expect(find.text('Browse All Products'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));
      await refresh;
      expect(provider.state, MarketplaceScreenState.ready);
      expect(find.byType(ShimmerBox), findsNothing);
    });

    testWidgets('closing search resets the browse grid (no query leak)',
        (tester) async {
      final provider = MarketplaceProvider();
      await tester.pumpWidget(_wrap(const MarketplaceHomeScreen(), provider));
      await _preload(provider, tester);
      final total = provider.visibleProducts.length;
      expect(total, greaterThan(0));

      await tester.tap(find.text('Search parts, oils, tyres...'));
      await _navSettle(tester);
      await tester.enterText(find.byType(TextField), 'ngk');
      await tester.pump();
      expect(provider.searchQuery, 'ngk');
      expect(provider.visibleProducts.length, lessThan(total));

      await tester.pageBack();
      await _navSettle(tester);
      expect(provider.searchQuery, isEmpty,
          reason: 'leaving search must clear the hidden query');
      expect(provider.visibleProducts.length, total,
          reason: 'home grid must be unfiltered after closing search');
      expect(find.text('Browse All Products'), findsOneWidget);
    });

    testWidgets(
        'end-to-end: home -> search -> product -> cart -> checkout -> success',
        (tester) async {
      final provider = MarketplaceProvider();
      await tester.pumpWidget(_wrap(const MarketplaceHomeScreen(), provider));
      await _preload(provider, tester);

      await tester.tap(find.text('Search parts, oils, tyres...'));
      await _navSettle(tester);
      expect(find.byType(SearchScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ngk');
      await tester.pump();
      await tester.tap(find.text('NGK Iridium Spark Plug').first);
      await _navSettle(tester);
      expect(find.text('Add to Cart'), findsOneWidget);

      await tester.tap(find.text('Add to Cart'));
      await tester.pump();
      expect(provider.cartCount, 1);
      await tester.pump(const Duration(seconds: 5));

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await _navSettle(tester);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await _navSettle(tester);

      await tester.tap(find.byTooltip('Cart'));
      await _navSettle(tester);
      expect(find.textContaining('Proceed to Checkout'), findsOneWidget);

      await tester.tap(find.textContaining('Proceed to Checkout'));
      await _navSettle(tester);
      expect(find.byType(CheckoutScreen), findsOneWidget);

      await tester.tap(find.text('Add delivery address'));
      await _navSettle(tester);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full name'), 'Ravi Kumar');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone'), '9876543210');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Address'), '12 MG Road');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'PIN code'), '560001');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'City'), 'Bengaluru');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'State'), 'Karnataka');
      await tester.tap(find.text('Continue'));
      await _navSettle(tester);

      await tester.tap(find.textContaining('Place Order'));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));
      await _navSettle(tester);

      expect(find.byType(OrderSuccessScreen), findsOneWidget);
      expect(find.text('Order Placed!'), findsOneWidget);
      expect(provider.cart, isEmpty);
      expect(ordersList.first['id'], startsWith('MKP-'));
    });

    testWidgets(
        'all screens render without overflow in light/dark at 320/360/390/412/600/768dp',
        (tester) async {
      for (final width in [320.0, 360.0, 390.0, 412.0, 600.0, 768.0]) {
        for (final dark in [false, true]) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final provider = MarketplaceProvider();
          await tester.pumpWidget(_wrapThemed(
              const MarketplaceHomeScreen(), provider,
              dark: dark));
          await _preload(provider, tester);
          expect(tester.takeException(), isNull,
              reason: 'home ${width}dp dark=$dark');

          await tester.pumpWidget(
              _wrapThemed(const SearchScreen(), provider, dark: dark));
          await _preload(provider, tester);
          expect(tester.takeException(), isNull,
              reason: 'search ${width}dp dark=$dark');

          await tester.pumpWidget(_wrapThemed(
              ProductDetailScreen(productId: _sparkPlug.id), provider,
              dark: dark));
          await tester.pump();
          expect(tester.takeException(), isNull,
              reason: 'detail ${width}dp dark=$dark');

          await tester.pumpWidget(_wrapThemed(
              CategoryScreen(categoryId: kMarketplaceCategories.first.id),
              provider,
              dark: dark));
          await tester.pump();
          expect(tester.takeException(), isNull,
              reason: 'category ${width}dp dark=$dark');

          provider.addToCart(_sparkPlug, quantity: 1);
          await tester.pumpWidget(_wrapThemed(
              ProductDetailScreen(productId: _sparkPlug.id), provider,
              dark: dark));
          await tester.pump();
          expect(tester.takeException(), isNull,
              reason: 'detail-in-cart ${width}dp dark=$dark');

          provider.addToCart(_sparkPlug, quantity: 2);
          await tester.pumpWidget(
              _wrapThemed(const CartScreen(), provider, dark: dark));
          await tester.pump();
          expect(tester.takeException(), isNull,
              reason: 'cart ${width}dp dark=$dark');

          await tester.pumpWidget(
              _wrapThemed(const CheckoutScreen(), provider, dark: dark));
          await tester.pump();
          expect(tester.takeException(), isNull,
              reason: 'checkout ${width}dp dark=$dark');

          provider.toggleWishlist(_chainKit);
          await tester.pumpWidget(
              _wrapThemed(const WishlistScreen(), provider, dark: dark));
          await tester.pump();
          expect(tester.takeException(), isNull,
              reason: 'wishlist ${width}dp dark=$dark');

          final placing = provider.placeOrder(
            address: const CheckoutAddress(
              name: 'Ravi Kumar',
              phone: '9876543210',
              address: '12 MG Road',
              city: 'Bengaluru',
              state: 'Karnataka',
              pincode: '560001',
            ),
            paymentMethod: 'UPI',
          );
          await tester.pump(const Duration(milliseconds: 800));
          await tester.pump(const Duration(milliseconds: 800));
          expect(await placing, isTrue);
          await tester.pumpWidget(
              _wrapThemed(const OrderSuccessScreen(), provider, dark: dark));
          await tester.pump();
          expect(tester.takeException(), isNull,
              reason: 'success ${width}dp dark=$dark');
        }
      }
    });
  });

  group('QA & runtime stabilization (Sprint 1.8.2)', () {
    test('addToCart never creates a zero or negative quantity line', () {
      final provider = MarketplaceProvider();
      provider.addToCart(_sparkPlug, quantity: 0);
      expect(provider.cartCount, 1);
      expect(provider.cart.single.quantity, 1);

      provider.addToCart(_sparkPlug, quantity: -3);
      expect(provider.cartCount, 2);
      expect(provider.cart.single.quantity, 2);
    });

    test('failed refresh keeps the loaded catalog and the ready state', () async {
      final repo = _FlakyRepository();
      final provider = MarketplaceProvider(repository: repo);

      await provider.load();
      expect(provider.state, MarketplaceScreenState.ready);
      expect(provider.products, isNotEmpty);

      repo.fail = true;
      await provider.refresh();
      expect(provider.state, MarketplaceScreenState.ready);
      expect(provider.products, isNotEmpty);
      expect(provider.errorMessage, isNotNull);
    });

    test('failed load lands in the error state and retry recovers', () async {
      final repo = _FlakyRepository();
      final provider = MarketplaceProvider(repository: repo);

      repo.fail = true;
      await provider.load();
      expect(provider.state, MarketplaceScreenState.error);

      repo.fail = false;
      await provider.load();
      expect(provider.state, MarketplaceScreenState.ready);
      expect(provider.products, isNotEmpty);
    });

    testWidgets('every category page renders without a sliver crash',
        (tester) async {
      for (final category in kMarketplaceCategories) {
        final provider = MarketplaceProvider();
        await tester.pumpWidget(
            _wrap(CategoryScreen(categoryId: category.id), provider));
        await _preload(provider, tester);
        expect(tester.takeException(), isNull,
            reason: 'category ${category.id}');
        expect(find.text(category.name), findsOneWidget);
        expect(find.textContaining('product'), findsWidgets);
      }
    });

    testWidgets('cart title badge always matches the visible cart lines',
        (tester) async {
      final provider = MarketplaceProvider();
      await tester.pumpWidget(_wrap(const CartScreen(), provider));
      await tester.pump();

      expect(find.text('Cart (0)'), findsOneWidget);
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.byType(CartItemTile), findsNothing);

      provider.addToCart(_sparkPlug, quantity: 1);
      await tester.pump();
      expect(find.text('Cart (1)'), findsOneWidget);
      expect(find.byType(CartItemTile), findsOneWidget);
      expect(find.text('Your cart is empty'), findsNothing);

      provider.incrementQuantity(_sparkPlug.id);
      await tester.pump();
      expect(find.text('Cart (2)'), findsOneWidget);
      expect(find.byType(CartItemTile), findsOneWidget);

      provider.decrementQuantity(_sparkPlug.id);
      await tester.pump();
      expect(find.text('Cart (1)'), findsOneWidget);

      provider.addToCart(_chainKit);
      await tester.pump();
      expect(find.text('Cart (2)'), findsOneWidget);
      expect(find.byType(CartItemTile), findsNWidgets(2));

      provider.removeFromCart(_chainKit.id);
      await tester.pump();
      expect(find.text('Cart (1)'), findsOneWidget);
      expect(find.byType(CartItemTile), findsOneWidget);

      provider.clearCart();
      await tester.pump();
      expect(find.text('Cart (0)'), findsOneWidget);
      expect(find.byType(CartItemTile), findsNothing);
      expect(find.text('Your cart is empty'), findsOneWidget);
    });

    testWidgets('product already in cart shows Go to Cart, never Add to Cart',
        (tester) async {
      final provider = MarketplaceProvider();
      await tester.pumpWidget(
          _wrap(ProductDetailScreen(productId: _sparkPlug.id), provider));
      await _preload(provider, tester);
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('Go to Cart'), findsNothing);

      provider.addToCart(_sparkPlug, quantity: 1);
      await tester.pump();
      expect(find.text('Already in cart'), findsOneWidget);
      expect(find.text('Go to Cart'), findsOneWidget);
      expect(find.text('Add to Cart'), findsNothing);

      await tester.tap(find.text('Go to Cart'));
      await _navSettle(tester);
      expect(find.byType(CartScreen), findsOneWidget);
      expect(find.text('Cart (1)'), findsOneWidget);

      // Back must return to the product, not to a blank screen.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await _navSettle(tester);
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text('Go to Cart'), findsOneWidget);
    });

    testWidgets('cart opened from the marketplace pops back to it',
        (tester) async {
      final provider = MarketplaceProvider();
      provider.addToCart(_sparkPlug, quantity: 1);

      await tester.pumpWidget(
          _wrap(const MarketplaceHomeScreen(), provider));
      await _preload(provider, tester);

      await tester.tap(find.byTooltip('Cart'));
      await _navSettle(tester);
      expect(find.byType(CartScreen), findsOneWidget);
      expect(find.text('Cart (1)'), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await _navSettle(tester);
      expect(find.byType(MarketplaceHomeScreen), findsOneWidget);
      expect(find.byType(CartScreen), findsNothing);
    });

    testWidgets('Home Quick Service Parts opens the Marketplace, not a snackbar',
        (tester) async {
      final homeProvider = HomeProvider(HomeRepository());
      final marketplace = MarketplaceProvider();

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeProvider>.value(value: homeProvider),
          ChangeNotifierProvider<MarketplaceProvider>.value(
              value: marketplace),
          ChangeNotifierProvider<LocationProvider>(
              create: (_) => _FakeLocationProvider()),
        ],
        child: const MaterialApp(home: HomeDashboard()),
      ));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));

      await tester.ensureVisible(find.text('Parts'));
      await tester.tap(find.text('Parts'));
      await _navSettle(tester);

      expect(find.byType(MarketplaceHomeScreen), findsOneWidget);
      expect(find.text('Parts service coming soon!'), findsNothing);

      await _preload(marketplace, tester);
      expect(find.text('Browse All Products'), findsOneWidget);
    });
  });
}
