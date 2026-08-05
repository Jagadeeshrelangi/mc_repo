import 'package:flutter/material.dart';
import 'package:mecha_connect/features/home/models/home_models.dart';
import 'package:mecha_connect/features/home/providers/home_provider.dart';
import 'package:mecha_connect/features/home/widgets/home_empty_view.dart';
import 'package:mecha_connect/features/home/widgets/quick_service_card.dart';
import 'package:mecha_connect/features/home/widgets/section_title.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';

class HomeSearchScreen extends StatefulWidget {
  final void Function(QuickService service)? onQuickServiceTap;
  final void Function(NearbyService service)? onNearbyTap;

  const HomeSearchScreen({
    super.key,
    this.onQuickServiceTap,
    this.onNearbyTap,
  });

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<QuickService> _filteredServices(List<QuickService> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((s) => s.label.toLowerCase().contains(q)).toList();
  }

  List<NearbyService> _filteredNearby(List<NearbyService> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.category.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HomeProvider>();

    final services = _filteredServices(provider.quickServices);
    final nearby = _filteredNearby(provider.nearbyServices);
    final hasQuery = _query.trim().isNotEmpty;
    final hasResults = services.isNotEmpty || nearby.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.grey100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search services, garages, parts...',
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded, size: 20),
              ),
              style: TextStyle(
                fontSize: AppResponsive.scaleFont(context, 15),
                color: isDark ? AppColors.darkText : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: AppResponsive.scale(context, 8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasResults && hasQuery)
              const HomeEmptyView(
                icon: Icons.search_off_rounded,
                title: 'No results found',
                message: 'Try a different keyword like "mechanic", "fuel" or "tyre".',
              )
            else if (!hasQuery)
              const HomeEmptyView(
                icon: Icons.travel_explore_rounded,
                title: 'Search Mecha Connect',
                message: 'Find quick services, nearby garages and more.',
              )
            else ...[
              if (services.isNotEmpty) ...[
                const SectionTitle(title: 'Quick Services'),
                SizedBox(height: AppResponsive.scale(context, 8)),
                QuickServicesGrid(
                  services: services,
                  onTap: widget.onQuickServiceTap,
                ),
                SizedBox(height: AppResponsive.scale(context, 24)),
              ],
              if (nearby.isNotEmpty) ...[
                const SectionTitle(title: 'Nearby Services'),
                SizedBox(height: AppResponsive.scale(context, 8)),
                _buildNearbyResults(context, nearby, isDark),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyResults(BuildContext context, List<NearbyService> nearby, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPadding(context),
      ),
      child: Column(
        children: nearby.map((service) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: InkWell(
                onTap: widget.onNearbyTap != null
                    ? () => widget.onNearbyTap!(service)
                    : null,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: isDark ? null : AppElevation.shadowLow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.brandOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.brandOrange,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: TextStyle(
                                fontSize: AppResponsive.scaleFont(context, 14),
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkText : AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xxs),
                            Text(
                              service.category,
                              style: TextStyle(
                                fontSize: AppResponsive.scaleFont(context, 12),
                                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
