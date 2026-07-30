import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/services/location_provider.dart';
import 'package:mecha_connect/theme/app_colors.dart';

class LocationSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  Timer? _debounce;

  LocationSearchDelegate() : super(searchFieldLabel: 'Search for a location...');

  @override
  ThemeData appBarTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: isDark ? AppColors.darkBg : AppColors.grey50,
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextTertiary : AppColors.grey400,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded, size: 20),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, size: 22),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchBody(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final location = context.read<LocationProvider>();
    if (query.length >= 3) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        location.searchLocations(query);
      });
    }
    return _buildSearchBody(context);
  }

  Widget _buildSearchBody(BuildContext context) {
    final location = context.watch<LocationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (query.length < 3) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 48, color: isDark ? AppColors.darkBorder : AppColors.grey300),
            const SizedBox(height: 12),
            Text(
              'Type at least 3 characters to search',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextTertiary : AppColors.grey400,
              ),
            ),
          ],
        ),
      );
    }

    if (location.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_rounded, size: 48, color: isDark ? AppColors.darkBorder : AppColors.grey300),
            const SizedBox(height: 12),
            Text(
              'No locations found',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextTertiary : AppColors.grey400,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: location.searchResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
      itemBuilder: (context, index) {
        final result = location.searchResults[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.place_rounded, size: 20, color: AppColors.brandOrange),
          ),
          title: Text(
            result['shortName'] as String,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkText : AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            result['name'] as String,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            location.selectSearchResult(result);
            close(context, result);
          },
        );
      },
    );
  }
}
