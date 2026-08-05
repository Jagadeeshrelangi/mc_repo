import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/theme/app_responsive.dart';

/// Quick filter chips (In Stock / 4★+ / Under ₹1,000) plus the Filter sheet
/// button. Reads and mutates provider state directly.
class QuickFilterChips extends StatelessWidget {
  final VoidCallback onOpenFilters;

  const QuickFilterChips({super.key, required this.onOpenFilters});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();

    Widget chip(String label, bool selected, VoidCallback onTap) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.horizontalPadding(context),
        ),
        children: [
          chip('In Stock', provider.inStockOnly, provider.toggleInStockOnly),
          chip(
            '4★ & above',
            provider.minRating >= 4.0,
            () => provider.setMinRating(provider.minRating >= 4.0 ? 0 : 4.0),
          ),
          chip(
            'Under ₹1,000',
            provider.maxPrice != null && provider.maxPrice! <= 1000,
            () => provider.setPriceRange(
              null,
              provider.maxPrice != null && provider.maxPrice! <= 1000
                  ? null
                  : 1000,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: ActionChip(
              avatar: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Filter'),
              onPressed: onOpenFilters,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
