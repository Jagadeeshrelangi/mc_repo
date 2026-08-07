import 'package:flutter/material.dart';
import 'package:mecha_connect/features/mechanic/models/models.dart';
import 'package:mecha_connect/features/mechanic/providers/mechanic_provider.dart';
import 'package:mecha_connect/features/mechanic/screens/booking_history_screen.dart';
import 'package:mecha_connect/features/mechanic/screens/mechanic_details_screen.dart';
import 'package:mecha_connect/features/mechanic/screens/nearby_mechanics_screen.dart';
import 'package:mecha_connect/features/mechanic/screens/vehicle_form_screen.dart';
import 'package:mecha_connect/features/mechanic/widgets/mechanic_card.dart';
import 'package:mecha_connect/features/mechanic/widgets/service_chip.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/widgets/app_loading.dart';
import 'package:provider/provider.dart';

class MechanicHomeScreen extends StatefulWidget {
  const MechanicHomeScreen({super.key});

  @override
  State<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

class _MechanicHomeScreenState extends State<MechanicHomeScreen> {
  int? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MechanicProvider>().loadHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final provider = context.watch<MechanicProvider>();
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: _buildAppBar(context, isDark),
      body: ConstrainedContent(
        child: RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(context, isDark),
                SizedBox(height: AppSpacing.sm),
                _buildLocationRow(context, isDark),
                SizedBox(height: AppSpacing.base),
                _buildVehicleSelector(context, isDark),
                SizedBox(height: AppSpacing.xl),
                _buildSectionTitle('Categories'),
                SizedBox(height: AppSpacing.sm),
                _buildCategoriesGrid(context, isDark),
                SizedBox(height: AppSpacing.xl),
                _buildEmergencyBanner(context),
                SizedBox(height: AppSpacing.xl),
                _buildSectionTitle('Featured Mechanics'),
                SizedBox(height: AppSpacing.sm),
                _buildFeaturedSection(context, isDark, provider),
                SizedBox(height: AppSpacing.xl),
                _buildSectionTitle('Nearby Mechanics'),
                Row(
                  children: [
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.only(right: AppResponsive.horizontalPadding(context)),
                      child: TextButton(
                        onPressed: () => _navigateToNearby(context),
                        child: Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandOrange)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xs),
                _buildNearbySection(context, isDark, provider),
                SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: context.bgSecondary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Mechanic',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const BookingHistoryScreen(),
            ));
          },
          icon: Icon(Icons.history_rounded, color: context.textSecondary),
          tooltip: 'Booking History',
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No new notifications'), behavior: SnackBarBehavior.floating),
            );
          },
          icon: Icon(Icons.notifications_outlined, color: context.textSecondary),
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppResponsive.horizontalPadding(context), AppSpacing.sm, AppResponsive.horizontalPadding(context), 0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: context.border, width: 1),
          boxShadow: context.shadowLow,
        ),
        child: TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Search mechanics, services...',
            hintStyle: TextStyle(fontSize: 14, color: context.textTertiary),
            prefixIcon: Icon(Icons.search_rounded, color: context.textTertiary, size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mechanic search coming in Sprint 2!'), behavior: SnackBarBehavior.floating),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationRow(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppResponsive.horizontalPadding(context), 0, AppResponsive.horizontalPadding(context), 0),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, size: 18, color: AppColors.brandOrange),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Surampalem, Andhra Pradesh',
              style: TextStyle(fontSize: 13, color: context.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                SizedBox(width: 4),
                Text('Available', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.successDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelector(BuildContext context, bool isDark) {
    final provider = context.read<MechanicProvider>();
    final vehicle = provider.selectedVehicle ?? 'Honda Activa 6G';
    return Padding(
      padding: EdgeInsets.fromLTRB(AppResponsive.horizontalPadding(context), 0, AppResponsive.horizontalPadding(context), 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: context.borderSoft),
        ),
        child: Row(
          children: [
            Icon(Icons.directions_car_rounded, size: 20, color: AppColors.brandOrange),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                vehicle,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const VehicleFormPage(),
                  ));
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandOrangeSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandOrange)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.brandOrange),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: AppResponsive.horizontalPadding(context)),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: context.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context, bool isDark) {
    final categories = context.watch<MechanicProvider>().categories;
    if (categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppResponsive.horizontalPadding(context) - 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(categories.length, (i) {
          final cat = categories[i];
          return ServiceChip(
            label: cat.name,
            icon: cat.icon,
            iconColor: cat.color,
            isSelected: _selectedCategory == i,
            onTap: () {
              setState(() => _selectedCategory = _selectedCategory == i ? null : i);
              if (_selectedCategory == i) {
                _navigateToNearby(context);
              }
            },
          );
        }),
      ),
    );
  }

  Widget _buildEmergencyBanner(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppResponsive.horizontalPadding(context)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Emergency mechanic dispatch initiated!'),
                backgroundColor: Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
                ),
                SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emergency Mechanic', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      SizedBox(height: 2),
                      Text('Immediate dispatch • 24/7', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(BuildContext context, bool isDark, MechanicProvider provider) {
    if (provider.state == MechanicScreenState.loading) return _buildFeaturedSkeleton();
    if (provider.state == MechanicScreenState.error || provider.state == MechanicScreenState.empty) {
      return _buildErrorInline(context, provider);
    }
    final featured = provider.featuredMechanics;
    if (featured.isEmpty) return _buildEmptyInline(context);
    return _buildFeaturedMechanics(context, isDark, featured);
  }

  Widget _buildNearbySection(BuildContext context, bool isDark, MechanicProvider provider) {
    if (provider.state == MechanicScreenState.loading) return _buildNearbySkeleton();
    if (provider.state == MechanicScreenState.error || provider.state == MechanicScreenState.empty) {
      return _buildErrorInline(context, provider);
    }
    final nearby = provider.mechanics.take(3).toList();
    if (nearby.isEmpty) return _buildEmptyInline(context);
    return _buildNearbyMechanics(context, isDark, nearby);
  }

  Widget _buildFeaturedMechanics(BuildContext context, bool isDark, List<MechanicInfo> featured) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = AppResponsive.horizontalPadding(context);
    final cardWidth = screenWidth <= 480 ? screenWidth - hPad * 2 - 16 : 260.0;
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        itemCount: featured.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final mech = featured[index];
          return SizedBox(
            width: cardWidth,
            child: MechanicCard(
              mechanic: mech,
              variant: MechanicCardVariant.compact,
              onTap: () => _navigateToDetails(context, mech),
              onViewProfile: () => _navigateToDetails(context, mech),
              onCall: () => _showCallSnackbar(context, mech.name, mech.phone),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNearbyMechanics(BuildContext context, bool isDark, List<MechanicInfo> nearby) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppResponsive.horizontalPadding(context)),
      child: Column(
        children: List.generate(nearby.length, (i) {
          final mech = nearby[i];
          return Padding(
            padding: EdgeInsets.only(bottom: i < nearby.length - 1 ? AppSpacing.sm : 0),
            child: MechanicCard(
              mechanic: mech,
              onTap: () => _navigateToDetails(context, mech),
              onViewProfile: () => _navigateToDetails(context, mech),
              onCall: () => _showCallSnackbar(context, mech.name, mech.phone),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorInline(BuildContext context, MechanicProvider provider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppResponsive.horizontalPadding(context)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                provider.errorMessage ?? 'Could not load mechanics.',
                style: const TextStyle(fontSize: 13, color: AppColors.error),
              ),
            ),
            TextButton(
              onPressed: () => provider.refresh(),
              child: const Text('Retry', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInline(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppResponsive.horizontalPadding(context)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: context.borderSoft),
        ),
        child: Column(
          children: [
            Icon(Icons.build_circle_outlined, size: 40, color: context.textTertiary),
            const SizedBox(height: AppSpacing.sm),
            Text('No mechanics available', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
          ],
        ),
      ),
    );
  }

  void _navigateToNearby(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const NearbyMechanicsScreen(),
    ));
  }

  void _navigateToDetails(BuildContext context, MechanicInfo mechanic) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MechanicDetailsScreen(mechanic: mechanic),
    ));
  }

  void _showCallSnackbar(BuildContext context, String name, String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $name...'), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildFeaturedSkeleton() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppResponsive.horizontalPadding(context)),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => _buildCompactSkeletonCard(),
      ),
    );
  }

  Widget _buildCompactSkeletonCard() {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.borderSoft, width: 0.5),
      ),
      child: Row(
        children: [
          AppShimmer(width: 52, height: 52, borderRadius: AppSpacing.radiusMd),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppShimmer(width: 100, height: 14),
                SizedBox(height: AppSpacing.sm),
                AppShimmer(width: 80, height: 11),
                SizedBox(height: AppSpacing.xs),
                AppShimmer(width: 60, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbySkeleton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppResponsive.horizontalPadding(context)),
      child: Column(
        children: List.generate(3, (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
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
                    children: [
                      AppShimmer(width: 140, height: 15),
                      SizedBox(height: AppSpacing.sm),
                      AppShimmer(width: 100, height: 12),
                      SizedBox(height: AppSpacing.sm),
                      AppShimmer(width: 180, height: 36, borderRadius: 10),
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
}
