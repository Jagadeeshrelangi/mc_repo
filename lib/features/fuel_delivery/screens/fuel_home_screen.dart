import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/widgets/app_loading.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/fuel_provider.dart';
import '../widgets/widgets.dart';
import 'fuel_booking_screen.dart';
import 'order_history_screen.dart';

class FuelHomeScreen extends StatefulWidget {
  const FuelHomeScreen({super.key});

  @override
  State<FuelHomeScreen> createState() => _FuelHomeScreenState();
}

class _FuelHomeScreenState extends State<FuelHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<FuelProvider>();
      if (provider.state == FuelScreenState.initial ||
          provider.state == FuelScreenState.error) {
        provider.loadHome();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FuelProvider>();
    final recentOrders = provider.orderHistory.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Delivery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Order History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.state == FuelScreenState.initial
            ? provider.loadHome
            : provider.refreshHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(context),
              const SizedBox(height: 24),
              _sectionHeader(context, 'Quick Order', 'Order fuel in seconds'),
              const SizedBox(height: 12),
              _buildFuelTypeQuickSelect(context),
              const SizedBox(height: 24),
              _buildEmergencyBanner(context),
              const SizedBox(height: 24),
              if (recentOrders.isNotEmpty) ...[
                _sectionHeader(context, 'Recent Orders', 'Your recent deliveries'),
                const SizedBox(height: 12),
                ...recentOrders.map(
                  (order) => RecentOrderCard(
                    order: order,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFuelTypeQuickSelect(BuildContext context) {
    final provider = context.watch<FuelProvider>();

    switch (provider.state) {
      case FuelScreenState.initial:
      case FuelScreenState.loading:
        return const SizedBox(
          height: 130,
          child: Center(child: AppLoading()),
        );
      case FuelScreenState.error:
        return FuelErrorState(
          icon: Icons.local_gas_station_rounded,
          title: 'Couldn\'t load fuel options',
          message: provider.errorMessage ?? 'Something went wrong. Please try again.',
          retryLabel: 'Retry',
          onRetry: provider.loadHome,
        );
      case FuelScreenState.empty:
        return FuelEmptyState(
          icon: Icons.local_gas_station_rounded,
          title: 'No fuel types available',
          subtitle: 'Fuel options will appear here shortly.',
          actionLabel: 'Refresh',
          onAction: provider.loadHome,
        );
      case FuelScreenState.ready:
        break;
    }

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: provider.fuelTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final fuelType = provider.fuelTypes[i];
          return FuelTypeCard(
            fuelType: fuelType,
            isSelected: provider.selectedFuelType == fuelType,
            onTap: () {
              context.read<FuelProvider>().selectFuelType(fuelType);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FuelBookingScreen()),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandOrange, AppColors.brandOrangeLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_gas_station_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fuel Delivery',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Get fuel delivered to your vehicle',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _bannerChip(Icons.timer_outlined, '15-30 min'),
              _bannerChip(Icons.monetization_on_outlined, '₹29 delivery'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FuelBookingScreen()),
              ),
              icon: const Icon(Icons.electric_rickshaw_rounded, size: 20),
              label: const Text(
                'Order Fuel Now',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.brandOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyBanner(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        final provider = context.read<FuelProvider>();
        provider.selectFuelType(FuelType.petrol);
        provider.setQuantity(3);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FuelBookingScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFFF87171)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.emergency_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Fuel?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Tap to order 3L petrol urgently',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
