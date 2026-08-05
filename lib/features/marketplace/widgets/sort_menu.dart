import 'package:flutter/material.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';

/// Popup menu listing the available SortOptions against the current value.
class SortMenu extends StatelessWidget {
  final MarketplaceProvider provider;

  const SortMenu({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      tooltip: 'Sort',
      icon: const Icon(Icons.sort_rounded),
      initialValue: provider.sortOption,
      onSelected: provider.setSortOption,
      itemBuilder: (context) => [
        for (final option in SortOption.values)
          PopupMenuItem(
            value: option,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: provider.sortOption == option
                      ? Icon(Icons.check_rounded,
                          size: 18, color: Theme.of(context).colorScheme.primary)
                      : const SizedBox.shrink(),
                ),
                Text(option.label),
              ],
            ),
          ),
      ],
    );
  }
}
