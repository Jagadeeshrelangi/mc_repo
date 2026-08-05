import 'package:flutter/material.dart';
import 'package:mecha_connect/homescreen/drawerscreen.dart';
import 'package:mecha_connect/features/ai/navigation.dart';
import 'package:mecha_connect/features/home/models/home_models.dart';
import 'package:mecha_connect/features/home/screens/home_search_screen.dart';
import 'package:mecha_connect/features/mechanic/screens/vehicle_form_screen.dart';
import 'package:mecha_connect/features/fuel_delivery/screens/fuel_home_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/marketplace_home_screen.dart';
import 'package:mecha_connect/features/profile/navigation.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/widgets/location_header.dart';

class ServiceSelectionScreen extends StatefulWidget {
  const ServiceSelectionScreen({super.key});

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimations = List.generate(5, (index) {
      final start = (index * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.grey50,
      endDrawer: const ProfileDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPremiumHeader(context, isDark),
              const LocationHeader(),
              _buildSearchBar(context, isDark),
              FadeTransition(
                opacity: _fadeAnimations[0],
                child: _buildSosCard(context, isDark),
              ),
              FadeTransition(
                opacity: _fadeAnimations[1],
                child: _buildVehicleHealthCard(context, isDark),
              ),
              FadeTransition(
                opacity: _fadeAnimations[2],
                child: _buildQuickServices(context, isDark),
              ),
              FadeTransition(
                opacity: _fadeAnimations[3],
                child: _buildRecentActivity(context, isDark),
              ),
              FadeTransition(
                opacity: _fadeAnimations[4],
                child: _buildPromoBanner(context, isDark),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jagadeesh',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.textPrimary,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
          _buildIconButton(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => openNotificationSettings(context),
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Scaffold.of(context).openEndDrawer(),
            child: Semantics(
              button: true,
              label: 'Open profile menu',
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: AppElevation.shadowBrandLight,
                ),
                child: const Center(
                  child: Text(
                    'JG',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Semantics(
        button: true,
        label: 'Search services',
        child: GestureDetector(
          onTap: () => _openSearch(context),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.grey200,
                width: 1,
              ),
              boxShadow:
                  isDark ? AppElevation.shadowDarkLow : AppElevation.shadowLow,
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: AppColors.grey400,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'What do you need today?',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark ? AppColors.darkTextTertiary : AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => HomeSearchScreen(
              onQuickServiceTap:
                  (service) => _handleQuickServiceTap(context, service),
              onNearbyTap: (service) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${service.name} details coming soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
      ),
    );
  }

  void _handleQuickServiceTap(BuildContext context, QuickService service) {
    switch (service.label) {
      case 'Mechanic':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VehicleFormPage()),
        );
        return;
      case 'Fuel':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FuelHomeScreen()),
        );
        return;
      case 'AI Diagnosis':
        openAiChat(context);
        return;
      case 'Parts':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MarketplaceHomeScreen()),
        );
        return;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${service.label} service coming soon!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Widget _buildSosCard(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Semantics(
        button: true,
        label: 'Emergency SOS — immediate roadside assistance',
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Connecting you to emergency roadside assistance...',
                ),
                backgroundColor: Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency SOS',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Immediate roadside assistance',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleHealthCard(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
            width: 0.5,
          ),
          boxShadow:
              isDark ? AppElevation.shadowDarkLow : AppElevation.shadowLow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.15),
                    AppColors.success.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                size: 26,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle Health',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.darkText : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Honda Activa 6G — 92% healthy',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            // Health ring
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: 0.92,
                      strokeWidth: 4,
                      backgroundColor:
                          (isDark ? AppColors.darkBorder : AppColors.grey200),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.success,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '92',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? AppColors.darkText : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickServices(BuildContext context, bool isDark) {
    final services = [
      _ServiceItem(
        Icons.build_rounded,
        'Mechanic',
        AppColors.brandOrange,
        AppColors.brandOrangeSoft,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VehicleFormPage()),
          );
        },
      ),
      _ServiceItem(
        Icons.local_gas_station_rounded,
        'Fuel',
        AppColors.brandBlue,
        AppColors.brandBlueSoft,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FuelHomeScreen()),
          );
        },
      ),
      _ServiceItem(
        Icons.psychology_rounded,
        'AI Diagnosis',
        AppColors.brandBlue,
        AppColors.brandBlueSoft,
        () {
          openAiChat(context);
        },
      ),
      _ServiceItem(
        Icons.settings_suggest_rounded,
        'Parts',
        AppColors.success,
        AppColors.successLight,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MarketplaceHomeScreen()),
          );
        },
      ),
      _ServiceItem(
        Icons.battery_charging_full_rounded,
        'Battery',
        AppColors.warning,
        AppColors.warningLight,
        () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Battery service coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
      _ServiceItem(
        Icons.local_shipping_rounded,
        'Towing',
        AppColors.grey500,
        AppColors.grey100,
        () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Towing service coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Services',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select the service you need',
            style: TextStyle(
              fontSize: 13,
              color:
                  isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  constraints.maxWidth >= 600
                      ? 4
                      : (constraints.maxWidth >= 360 ? 3 : 2);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: services.length,
                itemBuilder:
                    (context, index) =>
                        _buildServiceCard(services[index], isDark),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(_ServiceItem item, bool isDark) {
    return GestureDetector(
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grey100,
            width: 0.5,
          ),
          boxShadow:
              isDark ? AppElevation.shadowDarkLow : AppElevation.shadowLow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: item.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, size: 24, color: item.color),
            ),
            const SizedBox(height: 10),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Full activity history coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('View All', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          _buildActivityCard(
            icon: Icons.build_circle_outlined,
            iconColor: AppColors.brandOrange,
            title: 'Engine Oil Change',
            subtitle: 'Completed 2 days ago',
            status: 'Completed',
            statusColor: AppColors.success,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildActivityCard(
            icon: Icons.local_gas_station_outlined,
            iconColor: AppColors.brandBlue,
            title: 'Fuel Delivery — 5L Petrol',
            subtitle: 'Delivered to Andheri West',
            status: 'Delivered',
            statusColor: AppColors.success,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.grey100,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Coupon MECHA20 will apply at checkout.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '20% Off First Service',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Space Grotesk',
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Use code MECHA20 at checkout',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.grey100,
              width: 0.5,
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isDark ? AppColors.darkTextSecondary : AppColors.grey600,
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _ServiceItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ServiceItem(
    this.icon,
    this.label,
    this.color,
    this.bgColor,
    this.onTap,
  );
}
