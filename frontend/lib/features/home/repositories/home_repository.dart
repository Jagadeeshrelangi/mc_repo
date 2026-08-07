import 'package:mecha_connect/features/home/models/home_models.dart';

/// Data source for the Home dashboard.
///
/// Sprint 1.5: serves mock data with a simulated network delay.
/// Sprint 2+: swap internals for a real API client without touching the UI.
class HomeRepository {
  Future<HomeData> fetchHomeData() async {
    await Future.delayed(const Duration(milliseconds: 800));

    return const HomeData(
      quickServices: mockQuickServices,
      nearbyServices: mockNearbyServices,
      marketplaceItems: mockMarketplaceItems,
      activities: mockActivity,
      offers: [mockOffer],
    );
  }
}
