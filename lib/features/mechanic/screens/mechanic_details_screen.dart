import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/mechanic/mock_data.dart';
import 'package:mecha_connect/mechanic/widgets/mechanic_card.dart';
import 'package:mecha_connect/mechanic/widgets/primary_action_button.dart';
import 'package:mecha_connect/mechanic/screens/select_service_screen.dart';

class MechanicDetailsScreen extends StatelessWidget {
  final MechanicInfo mechanic;

  const MechanicDetailsScreen({super.key, required this.mechanic});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: ConstrainedContent(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(context),
                  SliverToBoxAdapter(child: _buildProfileSection(context, isDark)),
                  SliverToBoxAdapter(child: _buildStatsRow(context)),
                  SliverToBoxAdapter(child: _buildSection(context, 'Skills', _buildSkills(context))),
                  SliverToBoxAdapter(child: _buildSection(context, 'Languages', _buildLanguages(context))),
                  SliverToBoxAdapter(child: _buildSection(context, 'About', _buildAbout(context, isDark))),
                  SliverToBoxAdapter(child: _buildSection(context, 'Available Services', _buildServicesList(context))),
                  SliverToBoxAdapter(child: _buildSection(context, 'Service Charges', _buildCharges(context))),
                  SliverToBoxAdapter(child: _buildSection(context, 'Working Hours', _buildHours(context))),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: context.bgSecondary,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brandOrange.withValues(alpha: 0.8), AppColors.brandOrangeDark],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.person_rounded, size: 80, color: Colors.white.withValues(alpha: 0.3)),
              if (mechanic.isVerified)
                Positioned(
                  right: MediaQuery.sizeOf(context).width / 2 - 50,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppResponsive.horizontalPadding(context), AppSpacing.base, AppResponsive.horizontalPadding(context), 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mechanic.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary)),
          SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              RatingBadge(rating: mechanic.rating, reviewCount: mechanic.reviewCount),
              SizedBox(width: AppSpacing.sm),
              Text('${mechanic.experienceYears}+ years', style: TextStyle(fontSize: 13, color: context.textSecondary)),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 16, color: context.textTertiary),
              SizedBox(width: 4),
              Text('${mechanic.distanceKm.toStringAsFixed(1)} km away', style: TextStyle(fontSize: 13, color: context.textSecondary)),
              SizedBox(width: AppSpacing.base),
              Icon(Icons.access_time_rounded, size: 16, color: AppColors.success),
              SizedBox(width: 4),
              Text('${mechanic.etaMinutes} mins', style: TextStyle(fontSize: 13, color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppResponsive.horizontalPadding(context), AppSpacing.lg, AppResponsive.horizontalPadding(context), 0),
      child: Row(
        children: [
          _buildStatCard(context, Icons.work_rounded, '${mechanic.experienceYears}+', 'Years Exp'),
          SizedBox(width: AppSpacing.sm),
          _buildStatCard(context, Icons.reviews_rounded, '${mechanic.reviewCount}', 'Reviews'),
          SizedBox(width: AppSpacing.sm),
          _buildStatCard(context, Icons.build_rounded, '${mechanic.skills.length}', 'Services'),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderSoft),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.brandOrange),
            SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
            Text(label, style: TextStyle(fontSize: 11, color: context.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppResponsive.horizontalPadding(context), AppSpacing.xl, AppResponsive.horizontalPadding(context), 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary)),
          SizedBox(height: AppSpacing.sm),
          content,
        ],
      ),
    );
  }

  Widget _buildSkills(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: mechanic.skills.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.brandOrangeSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(s, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandOrange)),
      )).toList(),
    );
  }

  Widget _buildLanguages(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: mechanic.languages.map((l) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.bgTertiary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(l, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.textSecondary)),
      )).toList(),
    );
  }

  Widget _buildAbout(BuildContext context, bool isDark) {
    return Text(mechanic.about, style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.5));
  }

  Widget _buildServicesList(BuildContext context) {
    final services = mechanic.services.isNotEmpty ? mechanic.services : generalServices.take(4).toList();
    return Column(
      children: List.generate(services.length, (i) {
        final svc = services[i];
        return Padding(
          padding: EdgeInsets.only(bottom: i < services.length - 1 ? AppSpacing.sm : 0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderSoft),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.brandOrangeSoft, borderRadius: BorderRadius.circular(10)),
                  child: Icon(svc.icon, size: 20, color: AppColors.brandOrange),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(child: Text(svc.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary))),
                Text('₹${svc.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.brandOrange)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCharges(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSoft),
      ),
      child: Column(
        children: [
          _buildChargeRow(context, 'Inspection Fee', 'Free'),
          Divider(height: AppSpacing.lg, color: context.divider),
          _buildChargeRow(context, 'Service Charge', '₹${mechanic.priceStarting.toStringAsFixed(0)}+'),
          Divider(height: AppSpacing.lg, color: context.divider),
          _buildChargeRow(context, 'Emergency Surcharge', '₹100 (if applicable)'),
        ],
      ),
    );
  }

  Widget _buildChargeRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: context.textSecondary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
      ],
    );
  }

  Widget _buildHours(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSoft),
      ),
      child: Column(
        children: mechanic.workingHours.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.key, style: TextStyle(fontSize: 13, color: context.textSecondary)),
              Text(e.value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppResponsive.horizontalPadding(context), AppSpacing.base, AppResponsive.horizontalPadding(context), MediaQuery.of(context).padding.bottom + AppSpacing.base),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        border: Border(top: BorderSide(color: context.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44, width: 44,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling ${mechanic.name}...'), behavior: SnackBarBehavior.floating),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.bgTertiary,
                  foregroundColor: context.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(Icons.phone_rounded, size: 20),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: PrimaryActionButton(
              label: 'Book Mechanic',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SelectServiceScreen(mechanic: mechanic),
                ));
              },
            ),
          ),
        ],
      ),
    );
  }
}
