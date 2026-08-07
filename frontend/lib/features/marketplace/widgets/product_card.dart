import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/marketplace/models/product.dart';
import 'package:mecha_connect/features/marketplace/navigation.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/features/marketplace/utils/currency_formatter.dart';
import 'package:mecha_connect/features/marketplace/widgets/product_image.dart';
import 'package:mecha_connect/features/marketplace/widgets/rating_stars.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Product card used in horizontal rails and grids.
///
/// Reads cart/wishlist state from [MarketplaceProvider] so every instance
/// stays in sync without duplicated state.
class ProductCard extends StatelessWidget {
  final Product product;
  final double? width;

  const ProductCard({super.key, required this.product, this.width});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MarketplaceProvider>();
    // Rebuild only when this product's wishlist state changes (not on every
    // cart/catalog notification), so a full grid is cheap to keep in sync.
    final isWishlisted = context.select<MarketplaceProvider, bool>(
      (p) => p.isWishlisted(product.id),
    );

    return SizedBox(
      width: width,
      child: Material(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            provider.openProduct(product);
            openProduct(context, product.id);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.border, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImage(context, provider, isWishlisted),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.brand.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: context.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      RatingStars(
                        rating: product.rating,
                        size: 12,
                        showValue: true,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              formatINR(product.price),
                              style: const TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandOrange,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (product.discountPercent > 0) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                formatINR(product.mrp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.textTertiary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(
    BuildContext context,
    MarketplaceProvider provider,
    bool isWishlisted,
  ) {
    return SizedBox(
      height: 110,
      child: Stack(
        children: [
          Positioned.fill(child: ProductImage(product: product, height: 110)),
          if (product.discountPercent > 0)
            Positioned(
              left: 8,
              top: 8,
              child: _Badge(
                label: '${product.discountPercent.toStringAsFixed(0)}% OFF',
                background: AppColors.error,
              ),
            ),
          if (product.isFlashDeal)
            Positioned(
              left: 8,
              bottom: 8,
              child: const _Badge(
                label: '⚡ FLASH',
                background: AppColors.warning,
              ),
            ),
          Positioned(
            right: 6,
            top: 6,
            child: Material(
              color: context.cardBg.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => provider.toggleWishlist(product),
                customBorder: const CircleBorder(),
                child: Tooltip(
                  message:
                      isWishlisted ? 'Remove from wishlist' : 'Add to wishlist',
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Icon(
                      isWishlisted
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color:
                          isWishlisted ? AppColors.error : context.textTertiary,
                      semanticLabel:
                          isWishlisted
                              ? 'Remove ${product.name} from wishlist'
                              : 'Add ${product.name} to wishlist',
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (product.inStock)
            Positioned(
              right: 6,
              bottom: 6,
              child: Material(
                color: AppColors.brandOrange,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {
                    provider.addToCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to cart'),
                        duration: const Duration(milliseconds: 1500),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  customBorder: const CircleBorder(),
                  child: const Tooltip(
                    message: 'Add to cart',
                    child: Padding(
                      padding: EdgeInsets.all(13),
                      child: Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 18,
                        color: Colors.white,
                        semanticLabel: 'Add to cart',
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;

  const _Badge({required this.label, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
