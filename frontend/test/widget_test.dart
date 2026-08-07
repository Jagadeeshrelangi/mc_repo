import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mecha_connect/features/home/widgets/quick_service_card.dart';
import 'package:mecha_connect/features/marketplace/models/product.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/features/marketplace/widgets/product_card.dart';
import 'package:mecha_connect/features/marketplace/widgets/rating_stars.dart';
import 'package:provider/provider.dart';

/// Shared widgets used across the app: accessibility semantics and touch-target
/// sizes for the marketplace product card, rating stars, and the responsive
/// quick-services grid.
void main() {
  Product testProduct() => const Product(
    id: 'p-widget-test',
    name: 'Test Brake Pad',
    brand: 'Acme',
    brandId: 'acme',
    categoryId: 'brakes',
    price: 899,
    mrp: 1099,
    stock: 10,
  );

  Widget wrap(Widget child) => ChangeNotifierProvider<MarketplaceProvider>(
    create: (_) => MarketplaceProvider(),
    child: MaterialApp(home: Scaffold(body: child)),
  );

  testWidgets('RatingStars merges to a single "Rated X out of 5" semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RatingStars(rating: 4.5))),
    );

    final node = tester.getSemantics(find.byType(RatingStars));
    expect(node.label, 'Rated 4.5 out of 5');
  });

  testWidgets(
    'ProductCard wishlist & cart buttons are ≥44px and discoverable via tooltip',
    (tester) async {
      await tester.pumpWidget(wrap(ProductCard(product: testProduct())));
      await tester.pump();

      expect(find.byTooltip('Add to wishlist'), findsOneWidget);
      expect(find.byTooltip('Add to cart'), findsOneWidget);

      final wishlistSize = tester.getSize(find.byTooltip('Add to wishlist'));
      final cartSize = tester.getSize(find.byTooltip('Add to cart'));
      expect(wishlistSize.width, greaterThanOrEqualTo(44));
      expect(wishlistSize.height, greaterThanOrEqualTo(44));
      expect(cartSize.width, greaterThanOrEqualTo(44));
      expect(cartSize.height, greaterThanOrEqualTo(44));
    },
  );

  testWidgets('tapping the wishlist heart toggles its label', (tester) async {
    await tester.pumpWidget(wrap(ProductCard(product: testProduct())));
    await tester.pump();

    await tester.tap(find.byTooltip('Add to wishlist'));
    await tester.pump();

    expect(find.byTooltip('Remove from wishlist'), findsOneWidget);
    expect(find.byTooltip('Add to wishlist'), findsNothing);
  });

  testWidgets(
    'QuickServicesGrid lays out on a narrow 320px screen without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: QuickServicesGrid())),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(QuickServicesGrid), findsOneWidget);
    },
  );
}
