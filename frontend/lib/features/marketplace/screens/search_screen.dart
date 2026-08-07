import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/marketplace/navigation.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/features/marketplace/widgets/filter_chips.dart';
import 'package:mecha_connect/features/marketplace/widgets/filter_sheet.dart';
import 'package:mecha_connect/features/marketplace/widgets/marketplace_empty_state.dart';
import 'package:mecha_connect/features/marketplace/widgets/product_grid.dart';
import 'package:mecha_connect/features/marketplace/widgets/sort_menu.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Search + browse screen: product search over the catalog with filters and
/// sort, plus a categories tab.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _query;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(
      text: context.read<MarketplaceProvider>().searchQuery,
    );
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _query.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextField(
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search products, brands, categories...',
              isDense: true,
              filled: true,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _query,
                builder:
                    (_, value, __) =>
                        value.text.isEmpty
                            ? const SizedBox.shrink()
                            : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _query.clear();
                                provider.setSearchQuery('');
                              },
                            ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide(color: context.border),
              ),
            ),
            onChanged: provider.setSearchQuery,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Products'), Tab(text: 'Categories')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_ProductsTab(query: _query), _CategoriesTab()],
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  final TextEditingController query;

  const _ProductsTab({required this.query});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final results = provider.visibleProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: AppResponsive.horizontalPadding(context),
            right: AppResponsive.horizontalPadding(context),
            top: 12,
            bottom: 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  provider.searchQuery.trim().isEmpty
                      ? '${results.length} products'
                      : '${results.length} results for "${provider.searchQuery.trim()}"',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SortMenu(provider: provider),
            ],
          ),
        ),
        QuickFilterChips(
          onOpenFilters: () => showMarketplaceFilterSheet(context),
        ),
        const SizedBox(height: 8),
        Expanded(
          child:
              results.isEmpty
                  ? MarketplaceEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No results found',
                    message: 'Try a different keyword or remove filters.',
                    actionLabel: 'Clear Search',
                    onAction: () {
                      query.clear();
                      provider.resetBrowse();
                    },
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: ProductGrid(products: results, shrinkWrap: true),
                  ),
        ),
      ],
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final categories = provider.categories;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount =
        screenWidth >= 600 ? 4 : (screenWidth >= 360 ? 3 : 2);

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.base),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.86,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final count =
            provider
                .productsByCategory(category.id)
                .where((p) => p.inStock)
                .length;
        return InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: () => openCategory(context, category.id),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: context.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brandOrangeSoft,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    category.icon,
                    color: AppColors.brandOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count items',
                  style: TextStyle(fontSize: 10, color: context.textTertiary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
