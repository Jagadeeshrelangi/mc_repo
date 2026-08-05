import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/marketplace/navigation.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/features/marketplace/widgets/cart_item_tile.dart';
import 'package:mecha_connect/features/marketplace/widgets/coupon_field.dart';
import 'package:mecha_connect/features/marketplace/widgets/marketplace_empty_state.dart';
import 'package:mecha_connect/features/marketplace/widgets/price_summary_card.dart';
import 'package:mecha_connect/features/marketplace/screens/checkout_screen.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Shopping cart with quantity editing, coupon entry and the price summary.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final cart = provider.cart;
    final summary = provider.priceSummary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart (${provider.cartCount})'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: provider.clearCart,
              child: const Text('Clear'),
            ),
        ],
      ),
      body:
          cart.isEmpty
              ? MarketplaceEmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'Your cart is empty',
                message:
                    'Add parts and accessories and they will show up here.',
                actionLabel: 'Start Shopping',
                onAction: () => openSearch(context),
              )
              : ListView(
                padding: const EdgeInsets.all(AppSpacing.base),
                children: [
                  for (final item in cart)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CartItemTile(
                        item: item,
                        onQuantityChanged:
                            (q) => provider.setQuantity(item.product.id, q),
                        onRemove:
                            () => provider.removeFromCart(item.product.id),
                      ),
                    ),
                  const SizedBox(height: 6),
                  const CouponField(),
                  const SizedBox(height: 10),
                  PriceSummaryCard(
                    summary: summary,
                    itemCount: provider.cartCount,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
      bottomNavigationBar:
          cart.isEmpty
              ? null
              : SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    10,
                    AppSpacing.base,
                    10,
                  ),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    border: Border(top: BorderSide(color: context.border)),
                  ),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CheckoutScreen(),
                            ),
                          ),
                      child: Text(
                        'Proceed to Checkout  •  ₹${summary.grandTotal.round()}',
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
