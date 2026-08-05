import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/marketplace/models/offer.dart';
import 'package:mecha_connect/features/marketplace/models/product.dart';
import 'package:mecha_connect/features/marketplace/models/review.dart';
import 'package:mecha_connect/features/marketplace/navigation.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/features/marketplace/utils/currency_formatter.dart';
import 'package:mecha_connect/features/marketplace/widgets/product_image.dart';
import 'package:mecha_connect/features/marketplace/widgets/product_rail.dart';
import 'package:mecha_connect/features/marketplace/widgets/quantity_stepper.dart';
import 'package:mecha_connect/features/marketplace/widgets/rating_stars.dart';
import 'package:mecha_connect/features/marketplace/widgets/section_header.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Product detail: gallery, pricing, offers, specs, reviews, related products
/// and the sticky Add-to-Cart / Buy-Now bar.
class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  Product? get _product =>
      context.watch<MarketplaceProvider>().productById(widget.productId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<MarketplaceProvider>().productById(
        widget.productId,
      );
      if (p != null) context.read<MarketplaceProvider>().openProduct(p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final product = _product;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: context.textTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                'Product not found',
                style: TextStyle(color: context.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final quantityInCart = provider.quantityInCart(product.id);
    final inCart = quantityInCart > 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            actions: [
              IconButton(
                tooltip: 'Add to wishlist',
                onPressed: () => provider.toggleWishlist(product),
                icon: Icon(
                  provider.isWishlisted(product.id)
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  color:
                      provider.isWishlisted(product.id)
                          ? AppColors.brandOrange
                          : null,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: context.cardBg,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ProductImage(product: product, height: 260),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(context, product),
                  const SizedBox(height: 12),
                  _metaTiles(product),
                  const SizedBox(height: 16),
                  _offers(provider.offers),
                  const SizedBox(height: 20),
                  _sectionTitle(context, 'Description'),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(context, 'Specifications'),
                  const SizedBox(height: 8),
                  _specs(product),
                  const SizedBox(height: 20),
                  if (product.vehicleTypes.isNotEmpty) ...[
                    _sectionTitle(context, 'Compatible Vehicles'),
                    const SizedBox(height: 8),
                    _vehicleChips(product.vehicleTypes),
                    const SizedBox(height: 20),
                  ],
                  _reviews(product),
                ],
              ),
            ),
          ),
          if (product.reviews.isNotEmpty ||
              _related(provider, product).isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 88,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_related(provider, product).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SectionHeader(title: 'Related Products'),
                      ProductRail(products: _related(provider, product)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _bottomBar(context, product, inCart),
    );
  }

  List<Product> _related(MarketplaceProvider provider, Product product) {
    return provider.relatedProducts(product, limit: 10);
  }

  Widget _header(BuildContext context, Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              product.brand,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.brandOrange,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 8),
            if (product.isBestSeller)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandOrangeSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'BESTSELLER',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandOrange,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          product.name,
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: AppResponsive.scaleFont(context, 20),
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            RatingStars(rating: product.rating, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${product.rating.toStringAsFixed(1)} (${product.ratingCount} reviews)',
                style: TextStyle(fontSize: 12, color: context.textTertiary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatINR(product.price),
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: AppResponsive.scaleFont(context, 24),
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                formatINR(product.mrp),
                style: TextStyle(
                  fontSize: 14,
                  color: context.textTertiary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
            if (product.discountPercent > 0) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '${product.discountPercent.toStringAsFixed(0)}% OFF',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.successGreen,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Inclusive of all taxes',
          style: TextStyle(fontSize: 11, color: context.textTertiary),
        ),
      ],
    );
  }

  Widget _metaTiles(Product product) {
    return Row(
      children: [
        Expanded(
          child: _metaTile(
            Icons.local_shipping_outlined,
            'Delivery',
            product.deliveryEstimate,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metaTile(
            Icons.verified_outlined,
            'Warranty',
            product.warranty,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metaTile(
            Icons.speed_rounded,
            'In Stock',
            '${product.stock} units',
          ),
        ),
      ],
    );
  }

  Widget _metaTile(IconData icon, String title, String value) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: context.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: AppColors.brandOrange),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: context.textTertiary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _offers(List<Offer> offers) {
    if (offers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Available Offers'),
        const SizedBox(height: 8),
        for (final offer in offers)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.brandOrange.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              color:
                  context.isDark
                      ? AppColors.brandOrange.withValues(alpha: 0.15)
                      : AppColors.brandOrangeSoft,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_offer_rounded,
                  size: 16,
                  color: AppColors.brandOrange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${offer.title} ${offer.subtitle}. Use code ${offer.code}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _specs(Product product) {
    if (product.specifications.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < product.specifications.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: i.isOdd ? Colors.transparent : context.cardBgAlt,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.specifications[i].label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      product.specifications[i].value,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _vehicleChips(List<VehicleType> types) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in types)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brandOrangeSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(type.icon, size: 16, color: AppColors.brandOrange),
                const SizedBox(width: 6),
                Text(
                  type.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandOrange,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _reviews(Product product) {
    if (product.reviews.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Customer Reviews'),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              product.rating.toStringAsFixed(1),
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: AppResponsive.scaleFont(context, 32),
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingStars(rating: product.rating, size: 16),
                const SizedBox(height: 2),
                Text(
                  '${product.ratingCount} ratings',
                  style: TextStyle(fontSize: 12, color: context.textTertiary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final review in product.reviews) _reviewCard(review),
      ],
    );
  }

  Widget _reviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.brandOrangeSoft,
                child: Text(
                  review.author.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandOrange,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.author,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (review.isVerifiedPurchase) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: AppColors.successGreen,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      review.date,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${review.helpfulCount} helpful',
                style: TextStyle(fontSize: 11, color: context.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RatingStars(rating: review.rating, size: 14),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: AppResponsive.scaleFont(context, 16),
        fontWeight: FontWeight.w700,
        color: context.textPrimary,
      ),
    );
  }

  Widget _bottomBar(BuildContext context, Product product, bool inCart) {
    final provider = context.read<MarketplaceProvider>();
    final quantityInCart = provider.quantityInCart(product.id);
    final priceSummary = provider.priceSummaryForProduct(
      product,
      quantity: inCart ? quantityInCart : _quantity,
    );

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatINR(priceSummary.grandTotal),
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          inCart
                              ? 'Already in cart'
                              : '${product.stock} in stock',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!inCart)
                    QuantityStepper(
                      quantity: _quantity,
                      maxQuantity: product.stock,
                      onChanged: (v) => setState(() => _quantity = v),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      inCart
                          ? () => openCart(context)
                          : product.inStock
                          ? () {
                            provider.addToCart(product, quantity: _quantity);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                              ),
                            );
                          }
                          : null,
                  icon: Icon(
                    inCart
                        ? Icons.shopping_cart_rounded
                        : Icons.add_shopping_cart_rounded,
                    size: 18,
                  ),
                  label: Text(inCart ? 'Go to Cart' : 'Add to Cart'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
