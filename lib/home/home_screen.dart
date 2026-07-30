import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/home/widgets/home_header.dart';
import 'package:mecha_connect/home/widgets/location_card.dart';
import 'package:mecha_connect/home/widgets/search_bar_widget.dart';
import 'package:mecha_connect/home/widgets/emergency_card.dart';
import 'package:mecha_connect/home/widgets/vehicle_card.dart';
import 'package:mecha_connect/home/widgets/ai_assistant_card.dart';
import 'package:mecha_connect/home/widgets/quick_service_card.dart';
import 'package:mecha_connect/home/widgets/nearby_service_card.dart';
import 'package:mecha_connect/home/widgets/marketplace_card.dart';
import 'package:mecha_connect/home/widgets/recent_activity_card.dart';
import 'package:mecha_connect/home/widgets/offer_banner.dart';
import 'package:mecha_connect/home/widgets/section_title.dart';
import 'package:mecha_connect/homescreen/mechanic_screen.dart';
import 'package:mecha_connect/homescreen/petrol_page.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

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
          child: AppResponsive.isDesktop(context)
              ? _buildDesktopLayout(context)
              : _buildMobileLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppResponsive.scale(context, 16)),
          const HomeHeader(),
          SizedBox(height: AppResponsive.scale(context, 14)),
          const LocationCard(),
          SizedBox(height: AppResponsive.scale(context, 14)),
          const HomeSearchBar(),
          SizedBox(height: AppResponsive.scale(context, 16)),
          const EmergencyCard(),
          SizedBox(height: AppResponsive.scale(context, 16)),
          const VehicleCard(),
          SizedBox(height: AppResponsive.scale(context, 20)),
          const AIAssistantCard(),
          SizedBox(height: AppResponsive.scale(context, 24)),
          const SectionTitle(title: 'Quick Services'),
          SizedBox(height: AppResponsive.scale(context, 8)),
          QuickServicesGrid(
            onTap: (service) {
              switch (service.label) {
                case 'Mechanic':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleFormPage()));
                case 'Fuel':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FuelSelectionPage()));
                default:
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${service.label} service coming soon!'), behavior: SnackBarBehavior.floating),
                  );
              }
            },
          ),
          SizedBox(height: AppResponsive.scale(context, 24)),
          SectionTitle(
            title: 'Nearby Services',
            actionLabel: 'View All',
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All nearby services coming soon!'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
          SizedBox(height: AppResponsive.scale(context, 8)),
          const NearbyServicesList(),
          SizedBox(height: AppResponsive.scale(context, 24)),
          SectionTitle(
            title: 'Marketplace',
            actionLabel: 'Shop All',
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Full marketplace coming soon!'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
          SizedBox(height: AppResponsive.scale(context, 8)),
          const MarketplaceList(),
          SizedBox(height: AppResponsive.scale(context, 24)),
          const SectionTitle(title: 'Recent Activity'),
          SizedBox(height: AppResponsive.scale(context, 8)),
          const RecentActivityList(),
          SizedBox(height: AppResponsive.scale(context, 24)),
          const SectionTitle(title: 'Offers'),
          SizedBox(height: AppResponsive.scale(context, 8)),
          const OfferBanner(),
          SizedBox(height: AppResponsive.scale(context, 32)),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedContent(
        child: _buildMobileLayout(context),
      ),
    );
  }
}
