import 'package:flutter/material.dart';
import 'package:mecha_connect/features/marketplace/models/product.dart';
import 'package:mecha_connect/features/marketplace/widgets/product_card.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';

/// Horizontal, lazy product rail used for Flash Deals, Featured, Best Sellers,
/// Trending, Recently Viewed, Related and FBT rows.
class ProductRail extends StatelessWidget {
  final List<Product> products;
  final double cardWidth;

  const ProductRail({
    super.key,
    required this.products,
    this.cardWidth = 150,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.horizontalPadding(context),
        ),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.base),
        itemBuilder: (context, index) =>
            ProductCard(product: products[index], width: cardWidth),
      ),
    );
  }
}
