import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/marketplace/models/product.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Opens the marketplace filter bottom sheet. Filter selections are staged
/// locally and committed to the provider on Apply, so dragging the price
/// slider doesn't spam notifyListeners.
Future<void> showMarketplaceFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const MarketplaceFilterSheet(),
  );
}

class MarketplaceFilterSheet extends StatefulWidget {
  const MarketplaceFilterSheet({super.key});

  @override
  State<MarketplaceFilterSheet> createState() => _MarketplaceFilterSheetState();
}

class _MarketplaceFilterSheetState extends State<MarketplaceFilterSheet> {
  late final MarketplaceProvider _provider;

  late Set<String> _brands;
  late RangeValues _price;
  late bool _inStock;
  late double _rating;
  late Set<VehicleType> _vehicles;
  late SortOption _sort;

  double _maxCatalogPrice = 5000;

  @override
  void initState() {
    super.initState();
    _provider = context.read<MarketplaceProvider>();
    _brands = Set.of(_provider.selectedBrands);
    final maxPrice = _provider.products.fold<double>(
        0, (max, p) => p.mrp > max ? p.mrp : max);
    if (maxPrice > 0) _maxCatalogPrice = maxPrice;
    _price = RangeValues(
      _provider.minPrice ?? 0,
      _provider.maxPrice ?? _maxCatalogPrice,
    );
    _inStock = _provider.inStockOnly;
    _rating = _provider.minRating;
    _vehicles = Set.of(_provider.selectedVehicleTypes);
    _sort = _provider.sortOption;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _provider.resetFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Reset All'),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.divider),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  _sectionTitle('Brand'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final brand in _provider.brands)
                        FilterChip(
                          label: Text(brand.name),
                          selected: _brands.contains(brand.id),
                          onSelected: (_) => setState(() {
                            if (!_brands.add(brand.id)) _brands.remove(brand.id);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Price'),
                  RangeSlider(
                    values: _price,
                    min: 0,
                    max: _maxCatalogPrice,
                    divisions: 10,
                    labels: RangeLabels(
                      '₹${_price.start.round()}',
                      '₹${_price.end.round()}',
                    ),
                    onChanged: (v) => setState(() => _price = v),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₹${_price.start.round()}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary)),
                        Text('₹${_price.end.round()}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('In stock only'),
                    value: _inStock,
                    activeTrackColor: AppColors.brandOrange,
                    onChanged: (v) => setState(() => _inStock = v),
                  ),
                  const SizedBox(height: 12),
                  _sectionTitle('Rating'),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final r in [0.0, 4.0, 4.5])
                        ChoiceChip(
                          label: Text(r == 0 ? 'Any' : '$r★ & above'),
                          selected: _rating == r,
                          onSelected: (_) => setState(() => _rating = r),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Vehicle Type'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final v in VehicleType.values)
                        FilterChip(
                          avatar: Icon(v.icon, size: 16),
                          label: Text(v.label),
                          selected: _vehicles.contains(v),
                          onSelected: (_) => setState(() {
                            if (!_vehicles.add(v)) _vehicles.remove(v);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Sort By'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in SortOption.values)
                        ChoiceChip(
                          label: Text(s.label),
                          selected: _sort == s,
                          onSelected: (_) => setState(() => _sort = s),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _apply,
                  child: const Text('Apply Filters'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: context.textPrimary,
        ),
      ),
    );
  }

  void _apply() {
    _provider.setBrands(_brands);
    _provider.setVehicleTypes(_vehicles);
    _provider.setInStockOnly(_inStock);
    _provider.setPriceRange(
      _price.start > 0 ? _price.start : null,
      _price.end < _maxCatalogPrice ? _price.end : null,
    );
    _provider.setMinRating(_rating);
    _provider.setSortOption(_sort);
    Navigator.pop(context);
  }
}
