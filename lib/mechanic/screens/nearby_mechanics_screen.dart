import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/mechanic/mock_data.dart';
import 'package:mecha_connect/mechanic/widgets/mechanic_card.dart';
import 'package:mecha_connect/mechanic/widgets/service_chip.dart';
import 'package:mecha_connect/mechanic/screens/mechanic_details_screen.dart';

class NearbyMechanicsScreen extends StatefulWidget {
  const NearbyMechanicsScreen({super.key});

  @override
  State<NearbyMechanicsScreen> createState() => _NearbyMechanicsScreenState();
}

class _NearbyMechanicsScreenState extends State<NearbyMechanicsScreen> {
  String _sortBy = 'Nearest';
  final Set<String> _activeFilters = {};

  final List<String> _sortOptions = ['Nearest', 'Highest Rated', 'Lowest Price'];

  List<MechanicInfo> get _filteredMechanics {
    var list = List<MechanicInfo>.from(mockMechanics);

    if (_activeFilters.contains('Available Now')) {
      list = list.where((m) => m.isAvailable).toList();
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
    final mechanics = _filteredMechanics;
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
            Expanded(child: mechanics.isEmpty ? _buildEmptyState(context) : _buildList(context, mechanics)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      color: context.bgSecondary,
      padding: EdgeInsets.fromLTRB(AppResponsive.horizontalPadding(context), AppSpacing.sm, AppResponsive.horizontalPadding(context), AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
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
        ],
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

  Widget _buildList(BuildContext context, List<MechanicInfo> mechanics) {
    return ListView.separated(
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
