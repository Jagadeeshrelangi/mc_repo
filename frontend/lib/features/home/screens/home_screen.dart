import 'package:flutter/material.dart';
import 'package:mecha_connect/features/home/models/home_models.dart';
import 'package:mecha_connect/features/home/providers/home_provider.dart';
import 'package:mecha_connect/features/home/screens/home_search_screen.dart';
import 'package:mecha_connect/features/home/widgets/ai_assistant_card.dart';
import 'package:mecha_connect/features/home/widgets/emergency_card.dart';
import 'package:mecha_connect/features/home/widgets/home_empty_view.dart';
import 'package:mecha_connect/features/home/widgets/home_error_view.dart';
import 'package:mecha_connect/features/home/widgets/home_header.dart';
import 'package:mecha_connect/features/home/widgets/home_loading_skeleton.dart';
import 'package:mecha_connect/features/home/widgets/location_card.dart';
import 'package:mecha_connect/features/home/widgets/marketplace_card.dart';
import 'package:mecha_connect/features/home/widgets/nearby_service_card.dart';
import 'package:mecha_connect/features/home/widgets/offer_banner.dart';
import 'package:mecha_connect/features/home/widgets/quick_service_card.dart';
import 'package:mecha_connect/features/home/widgets/recent_activity_card.dart';
import 'package:mecha_connect/features/home/widgets/search_bar_widget.dart';
import 'package:mecha_connect/features/home/widgets/section_title.dart';
import 'package:mecha_connect/features/home/widgets/vehicle_card.dart';
import 'package:mecha_connect/features/ai/navigation.dart';
import 'package:mecha_connect/features/fuel_delivery/screens/fuel_home_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/marketplace_home_screen.dart';
import 'package:mecha_connect/features/mechanic/screens/vehicle_form_screen.dart';
import 'package:mecha_connect/features/profile/navigation.dart';
import 'package:mecha_connect/services/location_provider.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/widgets/location_picker_sheet.dart';
import 'package:provider/provider.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF0E1117),
                    Color(0xFF12151C),
                    Color(0xFF161A22),
                  ]
                : const [
                    Color(0xFFFAF8F5),
                    Color(0xFFF6F2EC),
                    Color(0xFFEFE9E0),
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Consumer<HomeProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const HomeLoadingSkeleton();
              }
              if (provider.error != null) {
                return HomeErrorView(
                  message: provider.error!,
                  onRetry: provider.refresh,
                );
              }
              final content = _buildContent(context, provider);
              final scrollable = SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: AppResponsive.isDesktop(context)
                    ? ConstrainedContent(child: content)
                    : content,
              );
              return RefreshIndicator(
                onRefresh: provider.refresh,
                child: scrollable,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeProvider provider) {
    final locationAddress =
        context.select<LocationProvider, String>((l) => l.selectedAddress);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppResponsive.scale(context, 16)),
          HomeHeader(
            user: UserProfile(
              name: provider.user.name,
              greeting: provider.greetingForHour(DateTime.now().hour),
            ),
            onNotificationsTap: () => _openNotifications(context),
          ),
          SizedBox(height: AppResponsive.scale(context, 14)),
          LocationCard(
            location: provider.location,
            address: locationAddress,
            onTap: () => showLocationPickerSheet(context),
          ),
          SizedBox(height: AppResponsive.scale(context, 14)),
          HomeSearchBar(
            onTap: () => _openSearch(context),
          ),
          SizedBox(height: AppResponsive.scale(context, 16)),
          EmergencyCard(
            onTap: () => _comingSoon(context, 'Emergency SOS'),
          ),
          SizedBox(height: AppResponsive.scale(context, 16)),
          VehicleCard(
            vehicle: provider.vehicle,
            onTap: () => _openVehicles(context),
          ),
          SizedBox(height: AppResponsive.scale(context, 20)),
          AIAssistantCard(
            onTap: () => _openChat(context),
          ),
          SizedBox(height: AppResponsive.scale(context, 24)),
          const SectionTitle(title: 'Quick Services'),
          SizedBox(height: AppResponsive.scale(context, 8)),
          if (provider.quickServices.isEmpty)
            const HomeEmptyView(
              icon: Icons.grid_view_rounded,
              title: 'No services available',
              message: 'Quick services will appear here.',
            )
          else
            QuickServicesGrid(
              services: provider.quickServices,
              onTap: (service) => _handleQuickService(context, service),
            ),
          SizedBox(height: AppResponsive.scale(context, 24)),
          SectionTitle(
            title: 'Nearby Services',
            actionLabel: 'View All',
            onAction: () => _comingSoon(context, 'All nearby services'),
          ),
          SizedBox(height: AppResponsive.scale(context, 8)),
          if (provider.nearbyServices.isEmpty)
            const HomeEmptyView(
              icon: Icons.location_off_outlined,
              title: 'No nearby services',
              message: 'Garages near you will appear here.',
            )
          else
            NearbyServicesList(
              services: provider.nearbyServices,
              onTap: (service) => _comingSoon(context, '${service.name} details'),
            ),
          SizedBox(height: AppResponsive.scale(context, 24)),
          SectionTitle(
            title: 'Marketplace',
            actionLabel: 'Shop All',
            onAction: () => _openMarketplace(context),
          ),
          SizedBox(height: AppResponsive.scale(context, 8)),
          if (provider.marketplaceItems.isEmpty)
            const HomeEmptyView(
              icon: Icons.shopping_bag_outlined,
              title: 'Marketplace is empty',
              message: 'Parts and accessories will appear here.',
            )
          else
            MarketplaceList(
              items: provider.marketplaceItems,
              onTap: (item) => _comingSoon(context, '${item.name} details'),
            ),
          SizedBox(height: AppResponsive.scale(context, 24)),
          const SectionTitle(title: 'Recent Activity'),
          SizedBox(height: AppResponsive.scale(context, 8)),
          if (provider.activities.isEmpty)
            const HomeEmptyView(
              icon: Icons.history_rounded,
              title: 'No activity yet',
              message: 'Your recent service history will show up here.',
            )
          else
            RecentActivityList(
              activities: provider.activities,
              onTap: (item) => _comingSoon(context, '${item.title} details'),
            ),
          SizedBox(height: AppResponsive.scale(context, 24)),
          const SectionTitle(title: 'Offers'),
          SizedBox(height: AppResponsive.scale(context, 8)),
          if (provider.offers.isEmpty)
            const HomeEmptyView(
              icon: Icons.local_offer_outlined,
              title: 'No offers right now',
              message: 'Exciting deals will be announced here.',
            )
          else
            for (final offer in provider.offers)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: OfferBanner(
                  offer: offer,
                  onTap: () => _comingSoon(context, 'Offer details'),
                ),
              ),
          SizedBox(height: AppResponsive.scale(context, 32)),
      ],
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeSearchScreen(
          onQuickServiceTap: (service) => _handleQuickService(context, service),
          onNearbyTap: (service) => _comingSoon(context, '${service.name} details'),
        ),
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    openNotificationSettings(context);
  }

  void _openVehicles(BuildContext context) {
    openMyVehicles(context);
  }

  void _openMarketplace(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MarketplaceHomeScreen()),
    );
  }

  void _openChat(BuildContext context) {
    openAiChat(context);
  }

  void _handleQuickService(BuildContext context, QuickService service) {
    switch (service.label) {
      case 'Mechanic':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VehicleFormPage()),
        );
        return;
      case 'Fuel':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FuelHomeScreen()),
        );
        return;
      case 'AI Diagnosis':
        _openChat(context);
        return;
      case 'Parts':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MarketplaceHomeScreen()),
        );
        return;
      default:
        _comingSoon(context, '${service.label} service');
    }
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
