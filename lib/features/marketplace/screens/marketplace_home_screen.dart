import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/marketplace/models/offer.dart';
import 'package:mecha_connect/features/marketplace/navigation.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/features/marketplace/widgets/category_rail.dart';
import 'package:mecha_connect/features/marketplace/widgets/filter_chips.dart';
import 'package:mecha_connect/features/marketplace/widgets/filter_sheet.dart';
import 'package:mecha_connect/features/marketplace/widgets/hero_banner.dart';
import 'package:mecha_connect/features/marketplace/widgets/marketplace_empty_state.dart';
import 'package:mecha_connect/features/marketplace/widgets/marketplace_error_view.dart';
import 'package:mecha_connect/features/marketplace/widgets/marketplace_shimmer.dart';
import 'package:mecha_connect/features/marketplace/widgets/product_grid.dart';
import 'package:mecha_connect/features/marketplace/widgets/product_rail.dart';
import 'package:mecha_connect/features/marketplace/widgets/section_header.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Marketplace landing screen: hero carousel, search entry, category rail,
/// curated product rails and a filterable browse-all grid.
class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MarketplaceProvider>();
      if (provider.state == MarketplaceScreenState.initial ||
          provider.state == MarketplaceScreenState.error) {
        provider.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();

    switch (provider.state) {
      case MarketplaceScreenState.initial:
      case MarketplaceScreenState.loading:
        return const Scaffold(body: MarketplaceLoadingSkeleton());
      case MarketplaceScreenState.error:
        return Scaffold(
          body: MarketplaceErrorView(
            message: provider.errorMessage ?? 'Unable to load marketplace.',
            onRetry: provider.load,
          ),
        );
      case MarketplaceScreenState.ready:
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: provider.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _TopBar()),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 4),
                  sliver: SliverToBoxAdapter(
                    child: _HomeContent(provider: provider),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppResponsive.horizontalPadding(context),
          right: AppResponsive.horizontalPadding(context),
          top: 12,
        ),
        child: Column(
          children: [
            Row(
              children: [
                if (Navigator.of(context).canPop()) ...[
                  IconButton(
                    tooltip: 'Back',
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: context.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    'Marketplace',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: AppResponsive.scaleFont(context, 24),
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                _IconAction(
                  icon: Icons.favorite_outline_rounded,
                  tooltip: 'Wishlist',
                  badge: context.watch<MarketplaceProvider>().wishlist.length,
                  onTap: () => openWishlist(context),
                ),
                const SizedBox(width: 4),
                _IconAction(
                  icon: Icons.shopping_cart_outlined,
                  tooltip: 'Cart',
                  badge: context.watch<MarketplaceProvider>().cartCount,
                  onTap: () => openCart(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => openSearch(context),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.grey50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: context.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: context.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search parts, oils, tyres...',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final int badge;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(icon, color: context.textPrimary),
        ),
        if (badge > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(
                color: AppColors.brandOrange,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badge',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  final MarketplaceProvider provider;

  const _HomeContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final railViewport = 150.0 + 8.0;
    final flashDeals = provider.flashDeals;
    final featured = provider.featuredProducts;
    final bestSellers = provider.bestSellers;
    final trending = provider.trendingProducts;
    final recommended = provider.recommendedProducts;
    final recentlyViewed = provider.recentlyViewed;
    final browse = provider.visibleProducts.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarketplaceHeroBanner(
          offers: provider.offers,
          onTap: (offer) => _openOffer(context, offer),
        ),
        const SizedBox(height: 16),
        CategoryRail(
          categories: provider.categories,
          onTap: (category) => openCategory(context, category.id),
        ),
        const SizedBox(height: 8),
        _OfferStrip(offers: provider.offers),
        const SizedBox(height: 20),
        if (flashDeals.isNotEmpty) ...[
          SectionHeader(
            title: 'Flash Deals',
            actionLabel: 'See All',
            onAction: () => openSearch(context),
          ),
          ProductRail(
            products: flashDeals,
            cardWidth: AppResponsive.responsive<double>(
              context,
              mobile: 150,
              tablet: 170,
              desktop: 190,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (featured.isNotEmpty) ...[
          SectionHeader(
            title: 'Featured',
            actionLabel: 'See All',
            onAction: () => openSearch(context),
          ),
          ProductRail(products: featured, cardWidth: railViewport),
          const SizedBox(height: 8),
        ],
        if (bestSellers.isNotEmpty) ...[
          SectionHeader(title: 'Best Sellers'),
          ProductRail(products: bestSellers, cardWidth: railViewport),
          const SizedBox(height: 8),
        ],
        if (trending.isNotEmpty) ...[
          SectionHeader(title: 'Trending Now'),
          ProductRail(products: trending, cardWidth: railViewport),
          const SizedBox(height: 8),
        ],
        if (recentlyViewed.isNotEmpty) ...[
          SectionHeader(title: 'Recently Viewed'),
          ProductRail(products: recentlyViewed, cardWidth: railViewport),
          const SizedBox(height: 8),
        ],
        if (recommended.isNotEmpty) ...[
          SectionHeader(
            title: 'Recommended for You',
            actionLabel: 'See All',
            onAction: () => openSearch(context),
          ),
          ProductRail(products: recommended, cardWidth: railViewport),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        SectionHeader(
          title: 'Browse All Products',
          actionLabel: 'See All',
          onAction: () => openSearch(context),
        ),
        QuickFilterChips(
          onOpenFilters: () => showMarketplaceFilterSheet(context),
        ),
        const SizedBox(height: 12),
        if (browse.isEmpty)
          MarketplaceEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No products match',
            message: 'Try removing some filters.',
            actionLabel: 'Reset Filters',
            onAction: provider.resetFilters,
          )
        else
          ProductGrid(products: browse, shrinkWrap: true),
        const SizedBox(height: 24),
      ],
    );
  }

  void _openOffer(BuildContext context, Offer offer) {
    if (offer.categoryId != null) {
      openCategory(context, offer.categoryId!);
    } else {
      openSearch(context);
    }
  }
}

/// Compact promo strip listing each offer's discount headline.
class _OfferStrip extends StatelessWidget {
  final List<Offer> offers;

  const _OfferStrip({required this.offers});

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.horizontalPadding(context),
        ),
        itemCount: offers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final offer = offers[index];
          return Container(
            width: 190,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [offer.gradientStart, offer.gradientEnd],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${offer.title} ${offer.subtitle}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
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
