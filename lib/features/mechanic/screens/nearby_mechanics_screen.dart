import 'package:flutter/material.dart';
import 'package:mecha_connect/features/mechanic/models/models.dart';
import 'package:mecha_connect/features/mechanic/providers/mechanic_provider.dart';
import 'package:mecha_connect/features/mechanic/screens/mechanic_details_screen.dart';
import 'package:mecha_connect/features/mechanic/widgets/mechanic_card.dart';
import 'package:mecha_connect/features/mechanic/widgets/service_chip.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/widgets/app_loading.dart';
import 'package:provider/provider.dart';

class NearbyMechanicsScreen extends StatefulWidget {
  const NearbyMechanicsScreen({super.key});

  @override
  State<NearbyMechanicsScreen> createState() => _NearbyMechanicsScreenState();
}

class _NearbyMechanicsScreenState extends State<NearbyMechanicsScreen> {
  String _sortBy = 'Nearest';
  final Set<String> _activeFilters = {};

  final List<String> _sortOptions = ['Nearest', 'Highest Rated', 'Lowest Price'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MechanicProvider>();
      if (provider.mechanics.isEmpty) provider.loadMechanics();
    });
  }

  List<MechanicInfo> _filteredMechanics(List<MechanicInfo> mechanics) {
    var list = List<MechanicInfo>.from(mechanics);

    if (_activeFilters.contains('Available Now')) {
      list = list.where((m) => m.isAvailable).toList();
    }
    if (_activeFilters.contains('Rating 4+')) {
      list = list.where((m) => m.rating >= 4.0).toList();
    }
    if (_activeFilters.contains('Under ₹500')) {
      list = list.where((m) => m.priceStarting <= 500).toList();
    }

    switch (_sortBy) {
      case 'Nearest':
        list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
      case 'Highest Rated':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Lowest Price':
        list.sort((a, b) => a.priceStarting.compareTo(b.priceStarting));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MechanicProvider>();
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Nearby Mechanics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary)),
      ),
      body: ConstrainedContent(
        child: Column(
          children: [
            _buildFilterBar(context),
            Expanded(child: _buildBody(context, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MechanicProvider provider) {
    switch (provider.state) {
      case MechanicScreenState.loading:
        return _buildLoading(context);
      case MechanicScreenState.error:
        return _buildError(context, provider);
      case MechanicScreenState.empty:
        return _buildEmptyState(context);
      case MechanicScreenState.initial:
      case MechanicScreenState.ready:
        final mechanics = _filteredMechanics(provider.mechanics);
        if (mechanics.isEmpty) {
          return _buildEmptyState(context);
        }
        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(AppResponsive.horizontalPadding(context)),
            itemCount: mechanics.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final mech = mechanics[index];
              return MechanicCard(
                mechanic: mech,
                onTap: () => _navigateToDetails(context, mech),
                onViewProfile: () => _navigateToDetails(context, mech),
                onCall: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling ${mech.name}...'), behavior: SnackBarBehavior.floating),
                  );
                },
              );
            },
          ),
        );
    }
  }

  Widget _buildLoading(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<MechanicProvider>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppResponsive.horizontalPadding(context)),
        children: List.generate(4, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 96,
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: context.borderSoft, width: 0.5),
            ),
            child: Row(
              children: [
                AppShimmer(width: 64, height: 64, borderRadius: AppSpacing.radiusMd),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppShimmer(width: 140, height: 15),
                      SizedBox(height: AppSpacing.sm),
                      AppShimmer(width: 100, height: 12),
                      SizedBox(height: AppSpacing.sm),
                      AppShimmer(width: 160, height: 30, borderRadius: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildError(BuildContext context, MechanicProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: context.textTertiary),
            SizedBox(height: AppSpacing.base),
            Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
            SizedBox(height: AppSpacing.sm),
            Text(
              provider.errorMessage ?? 'Could not load mechanics.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.textTertiary),
            ),
            SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () => provider.refresh(),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      color: context.bgSecondary,
      padding: EdgeInsets.fromLTRB(AppResponsive.horizontalPadding(context), AppSpacing.sm, AppResponsive.horizontalPadding(context), AppSpacing.base),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Available Now', Icons.check_circle_rounded),
            SizedBox(width: AppSpacing.sm),
            _buildFilterChip('Rating 4+', Icons.star_rounded),
            SizedBox(width: AppSpacing.sm),
            _buildFilterChip('Under ₹500', Icons.currency_rupee_rounded),
            SizedBox(width: AppSpacing.sm),
            _buildSortDropdown(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isActive = _activeFilters.contains(label);
    return ServiceChip(
      label: label,
      icon: icon,
      iconColor: isActive ? null : context.textTertiary,
      isSelected: isActive,
      onTap: () {
        setState(() {
          if (isActive) {
            _activeFilters.remove(label);
          } else {
            _activeFilters.add(label);
          }
        });
      },
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: context.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sort_rounded, size: 16, color: context.textSecondary),
          SizedBox(width: 4),
          Text(_sortBy, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
          SizedBox(width: 2),
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => _sortOptions.map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
            icon: Icon(Icons.arrow_drop_down_rounded, size: 20, color: context.textSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: context.textTertiary),
            SizedBox(height: AppSpacing.base),
            Text('No mechanics found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
            SizedBox(height: AppSpacing.sm),
            Text('Try adjusting your filters', style: TextStyle(fontSize: 14, color: context.textTertiary)),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context, MechanicInfo mechanic) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MechanicDetailsScreen(mechanic: mechanic),
    ));
  }
}
