import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/marketplace/navigation.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/features/marketplace/widgets/marketplace_empty_state.dart';
import 'package:mecha_connect/features/marketplace/widgets/product_grid.dart';
import 'package:mecha_connect/features/marketplace/widgets/sort_menu.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Products within a single category, with sorting.
class CategoryScreen extends StatelessWidget {
  final String categoryId;

  const CategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final category = provider.categoryById(categoryId);
    final products = provider.productsByCategory(categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(category?.name ?? 'Category'),
        actions: [SortMenu(provider: provider)],
      ),
      body: products.isEmpty
          ? MarketplaceEmptyState(
              icon: Icons.category_outlined,
              title: 'Nothing here yet',
              message: 'Products in this category are being added.',
              actionLabel: 'Browse All',
              onAction: () => openSearch(context),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '${products.length} product${products.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textTertiary,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    0,
                    AppSpacing.base,
                    AppSpacing.xl,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: ProductGrid(products: products),
                  ),
                ),
              ],
            ),
    );
  }
}
