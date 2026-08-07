import 'package:flutter/material.dart';
import 'package:mecha_connect/features/marketplace/models/product.dart';
import 'package:mecha_connect/features/marketplace/widgets/product_card.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';

/// Lazy product grid that adapts columns to the device (2/3/4). Use
/// `shrinkWrap: true` inside scroll views; `false` for a standalone grid.
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final bool shrinkWrap;

  const ProductGrid({super.key, required this.products, this.shrinkWrap = true});

  @override
  Widget build(BuildContext context) {
    final columns = AppResponsive.gridColumns(context);
    final padding = AppResponsive.horizontalPadding(context);
    final width = MediaQuery.sizeOf(context).width;

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.fromLTRB(padding, 0, padding, 0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.base,
        crossAxisSpacing: AppSpacing.base,
        mainAxisExtent: width < 1024 ? 250 : null,
        childAspectRatio: width >= 1024 ? 0.8 : 0.68,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => ProductCard(product: products[index]),
    );
  }
}
