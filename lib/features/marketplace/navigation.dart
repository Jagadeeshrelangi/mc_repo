import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/features/marketplace/screens/cart_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/category_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/product_detail_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/search_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/wishlist_screen.dart';

/// Route names used by the marketplace feature.
const String marketplaceScreenRoute = '/marketplace';
const String marketplaceProductRoute = '/marketplace/product';
const String marketplaceCategoryRoute = '/marketplace/category';
const String marketplaceSearchRoute = '/marketplace/search';
const String marketplaceCartRoute = '/marketplace/cart';
const String marketplaceWishlistRoute = '/marketplace/wishlist';

/// Fade-through page transition used across marketplace screens.
Route<void> _route(Widget screen) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, animation, secondaryAnimation) =>
        FadeTransition(opacity: animation, child: screen),
  );
}

void openProduct(BuildContext context, String productId) {
  Navigator.of(context).push(
    _route(ProductDetailScreen(productId: productId)),
  );
}

void openCategory(BuildContext context, String categoryId) {
  Navigator.of(context).push(
    _route(CategoryScreen(categoryId: categoryId)),
  );
}

void openSearch(BuildContext context) {
  final provider = context.read<MarketplaceProvider>();
  Navigator.of(context).push(_route(const SearchScreen())).then((_) {
    // Reset the search query when the search closes so it never leaks into the
    // home browse grid (the Home module keeps its search purely local; match
    // that: leaving search must leave no hidden filters behind).
    provider.setSearchQuery('');
  });
}

void openCart(BuildContext context) {
  Navigator.of(context).push(_route(const CartScreen()));
}

void openWishlist(BuildContext context) {
  Navigator.of(context).push(_route(const WishlistScreen()));
}
