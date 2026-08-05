import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mecha_connect/main.dart';
import 'package:mecha_connect/app_wiring.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/features/marketplace/screens/cart_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/checkout_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/marketplace_home_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/product_detail_screen.dart';
import 'package:mecha_connect/features/marketplace/widgets/cart_item_tile.dart';
import 'package:mecha_connect/features/marketplace/widgets/product_card.dart';

/// Test-local [NavigatorObserver] that records the set of navigators seen and
/// the push/pop counts, proving every marketplace screen shares ONE Navigator.
class _TestNavigatorObserver extends NavigatorObserver {
  final Set<int> _navigators = <int>{};
  int _pushCount = 0;
  int _popCount = 0;

  Set<int> get navigatorHashCodes => Set.unmodifiable(_navigators);
  int get pushCount => _pushCount;
  int get popCount => _popCount;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pushCount++;
    _navigators.add(navigator.hashCode);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _popCount++;
    _navigators.add(navigator.hashCode);
  }
}

/// Drives the REAL runtime path — the exact provider graph from `main()` and
/// the real Navigator — Home → Parts → Marketplace → Product → Add to Cart →
/// Cart → Checkout.
///
/// Unlike the isolated module tests, this test uses no test-local provider
/// wrapper: it boots [MyApp] with [buildRootProviders] (the same wiring
/// `main()` uses), so provider-scope and navigator bugs surface here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'onboarding_completed': true,
    });
  });

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    int tries = 60,
  }) async {
    for (var i = 0; i < tries; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    throw StateError('Timed out waiting for $finder');
  }

  testWidgets(
    'single MarketplaceProvider across the whole flow; cart badge, list and '
    'total always agree from the SAME instance',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final observer = _TestNavigatorObserver();
      await tester.pumpWidget(
        MultiProvider(
          providers: buildRootProviders(),
          child: MyApp(
            enableDevicePreview: false,
            navigatorObservers: [observer],
          ),
        ),
      );

      // Splash → BottomNavigation, tab 0 = HomeDashboard, which loads its
      // content (800ms) before the quick services appear.
      await tester.pump(const Duration(seconds: 3));
      await waitFor(tester, find.text('Parts'));
      // All bottom-nav tabs stay mounted inside the IndexedStack, so the
      // Services tab (also mounted, offstage) holds a second 'Parts' label.
      // The visible Home tab is the first match in tree order.
      await tester.tap(find.text('Parts').first);
      await tester.pump(); // route push frame
      await tester.pump(const Duration(milliseconds: 400)); // transition

      // Marketplace catalog loads in parallel (700ms), then the grid builds.
      await waitFor(tester, find.byType(ProductCard));

      expect(find.byType(MarketplaceHomeScreen), findsOneWidget);
      final marketProvider =
          tester
              .element(find.byType(MarketplaceHomeScreen))
              .read<MarketplaceProvider>();
      final marketId = marketProvider.hashCode;

      // Open the first product → ProductDetailScreen.
      await tester.tap(find.byType(ProductCard).first, warnIfMissed: false);
      await tester.pump(); // route push frame
      await tester.pump(const Duration(milliseconds: 400)); // transition
      expect(find.byType(ProductDetailScreen), findsOneWidget);

      final detailId =
          tester
              .element(find.byType(ProductDetailScreen))
              .read<MarketplaceProvider>()
              .hashCode;
      expect(
        detailId,
        marketId,
        reason:
            'ProductDetailScreen must read the SAME MarketplaceProvider '
            'as MarketplaceHomeScreen',
      );

      // Add to cart directly (no snackbar in flight) → badge/count = 1.
      final detailProvider =
          tester
              .element(find.byType(ProductDetailScreen))
              .read<MarketplaceProvider>();
      final productId =
          tester
              .widget<ProductDetailScreen>(find.byType(ProductDetailScreen))
              .productId;
      final product = detailProvider.productById(productId)!;
      detailProvider.addToCart(product);
      await tester.pump();
      expect(detailProvider.cartCount, 1);

      // Go to Cart → CartScreen.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Go to Cart'));
      await tester.pump(); // route push frame
      await tester.pump(const Duration(milliseconds: 400)); // transition
      expect(find.byType(CartScreen), findsOneWidget);

      final cartProvider =
          tester.element(find.byType(CartScreen)).read<MarketplaceProvider>();
      expect(
        cartProvider.hashCode,
        marketId,
        reason:
            'CartScreen must read the SAME MarketplaceProvider as the '
            'screen that added the product',
      );

      // Badge, line items and total derive from the same instance in one build.
      expect(cartProvider.cart.length, 1);
      expect(cartProvider.cartCount, 1);
      expect(find.text('Cart (1)'), findsOneWidget);
      expect(find.byType(CartItemTile), findsOneWidget);
      expect(find.textContaining('Proceed to Checkout'), findsOneWidget);
      final grandTotal = cartProvider.priceSummary.grandTotal.round();
      expect(
        find.textContaining('₹$grandTotal'),
        findsWidgets,
        reason:
            'Checkout bar total must match priceSummary.grandTotal '
            'computed from the same instance/cart',
      );

      // Proceed to Checkout.
      await tester.tap(find.textContaining('Proceed to Checkout'));
      await tester.pump(); // route push frame
      await tester.pump(const Duration(milliseconds: 400)); // transition
      expect(find.byType(CheckoutScreen), findsOneWidget);
      final checkoutId =
          tester
              .element(find.byType(CheckoutScreen))
              .read<MarketplaceProvider>()
              .hashCode;
      expect(
        checkoutId,
        marketId,
        reason: 'CheckoutScreen must read the SAME MarketplaceProvider',
      );

      // The navigator observer must have seen a single navigator (no nested
      // navigator scopes) and the full push sequence.
      expect(
        observer.navigatorHashCodes.length,
        1,
        reason: 'All marketplace screens must push onto the SAME Navigator',
      );
      expect(
        observer.pushCount,
        greaterThanOrEqualTo(4),
        reason:
            'Expected pushes: MarketplaceHome, ProductDetail, Cart, '
            'Checkout (plus the splash replacement)',
      );

      // Back navigation pops the same stack: Checkout → Cart → Product →
      // MarketplaceHome, and every screen keeps reading the SAME provider.
      final nav = tester.state<NavigatorState>(find.byType(Navigator).last);
      for (final expected in [
        CartScreen,
        ProductDetailScreen,
        MarketplaceHomeScreen,
      ]) {
        nav.pop();
        await tester.pump(); // pop frame
        await tester.pump(const Duration(milliseconds: 400)); // transition
        expect(
          find.byType(expected),
          findsOneWidget,
          reason: 'Back navigation must land on $expected',
        );
        final poppedId =
            tester
                .element(find.byType(expected))
                .read<MarketplaceProvider>()
                .hashCode;
        expect(
          poppedId,
          marketId,
          reason:
              '$expected must still read the SAME MarketplaceProvider '
              'after popping back',
        );
      }
      expect(
        observer.popCount,
        greaterThanOrEqualTo(3),
        reason: 'Checkout → Cart → Product → MarketplaceHome pops',
      );

      // Dispose the tree so no periodic widget timers remain pending.
      await tester.pumpWidget(const SizedBox.shrink());
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'empty cart shows the empty state and NO checkout bar (same gating)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: buildRootProviders(),
          child: MyApp(enableDevicePreview: false),
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      await waitFor(tester, find.text('Parts'));
      await tester.tap(find.text('Parts').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await waitFor(tester, find.byType(ProductCard));

      // Cart icon (badge 0) in the marketplace top bar → openCart.
      await tester.tap(find.byTooltip('Cart'));
      await tester.pump(); // route push frame
      await tester.pump(const Duration(milliseconds: 400)); // transition

      expect(find.byType(CartScreen), findsOneWidget);
      expect(find.textContaining('Your cart is empty'), findsOneWidget);
      expect(
        find.textContaining('Proceed to Checkout'),
        findsNothing,
        reason: 'A zero-item cart must not render a checkout bar',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
