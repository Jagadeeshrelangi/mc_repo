import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/marketplace/navigation.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/features/marketplace/utils/currency_formatter.dart';
import 'package:mecha_connect/features/marketplace/widgets/marketplace_empty_state.dart';
import 'package:mecha_connect/features/marketplace/widgets/product_image.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Saved-for-later list with move-to-cart and remove actions.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final items = provider.wishlist;

    return Scaffold(
      appBar: AppBar(title: Text('Wishlist (${items.length})')),
      body: items.isEmpty
          ? MarketplaceEmptyState(
              icon: Icons.favorite_outline_rounded,
              title: 'Nothing saved yet',
              message: 'Tap the heart on any product to save it here.',
              actionLabel: 'Explore Products',
              onAction: () => openSearch(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.base),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final product = item.product;
                final inCart = provider.quantityInCart(product.id) > 0;
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: context.border),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: ProductImage(product: product, height: 64),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () =>
                                  openProduct(context, product.id),
                              child: Text(
                                product.name,
                                style: TextStyle(
                                  fontSize: AppResponsive.scaleFont(context, 13),
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product.brand}  •  ${formatINR(product.price)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brandOrange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                  height: 32,
                                  child: OutlinedButton.icon(
                                    onPressed: inCart
                                        ? null
                                        : () => provider
                                            .moveWishlistToCart(product.id),
                                    icon: const Icon(Icons.add_shopping_cart_rounded,
                                        size: 16),
                                    label: Text(
                                        inCart ? 'In Cart' : 'Move to Cart'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove',
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      size: 20),
                                  color: context.textTertiary,
                                  onPressed: () => provider
                                      .removeFromWishlist(product.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
