import 'package:flutter/material.dart';
import '../models/models.dart';
import '../providers/fuel_provider.dart';
import '../widgets/widgets.dart';

class FuelHomeScreen extends StatefulWidget {
  const FuelHomeScreen({super.key});

  @override
  State<FuelHomeScreen> createState() => _FuelHomeScreenState();
}

class _FuelHomeScreenState extends State<FuelHomeScreen> {
  late final FuelProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = FuelProvider();
    _provider.addListener(_onProviderChange);
    _provider.loadFuelTypes();
  }

  void _onProviderChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChange);
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (_provider.state) {
      case FuelScreenState.initial:
      case FuelScreenState.loading:
        return const Center(child: CircularProgressIndicator());
      case FuelScreenState.error:
      case FuelScreenState.noInternet:
        return FuelErrorState(
          icon: _provider.state == FuelScreenState.noInternet ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
          title: _provider.state == FuelScreenState.noInternet ? 'No Internet Connection' : 'Something Went Wrong',
          message: _provider.errorMessage ?? 'Please try again',
          retryLabel: 'Retry',
          onRetry: () => _provider.loadFuelTypes(),
        );
      case FuelScreenState.noLocation:
        return FuelErrorState(
          icon: Icons.location_off_rounded,
          title: 'Location Unavailable',
          message: 'Enable GPS or set your location manually to order fuel delivery',
          retryLabel: 'Set Location Manually',
          onRetry: () => _provider.setError(FuelScreenState.ready, ''),
        );
      case FuelScreenState.empty:
        return FuelEmptyState(
          icon: Icons.local_shipping_rounded,
          title: 'No Partners Available',
          subtitle: _provider.errorMessage ?? 'Delivery partners are busy. Please try again shortly.',
          actionLabel: 'Search Again',
          onAction: () => _provider.runSearch(),
        );
      case FuelScreenState.ready:
        return RefreshIndicator(
          onRefresh: () async => _provider.loadFuelTypes(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBanner(theme),
                const SizedBox(height: 20),
                _buildSectionTitle(theme, 'Select Fuel Type'),
                const SizedBox(height: 12),
                _buildFuelTypeGrid(theme),
                const SizedBox(height: 20),
                if (_provider.selectedFuelType != null) ...[
                  _buildQuantitySelector(theme),
                  const SizedBox(height: 20),
                  if (_provider.priceEstimate != null) ...[
                    PriceBreakdown(estimate: _provider.priceEstimate!),
                    const SizedBox(height: 20),
                  ],
                  _buildSearchButton(theme),
                ],
                const SizedBox(height: 20),
                if (_provider.partners.isNotEmpty) ...[
                  _buildSectionTitle(theme, 'Available Partners'),
                  const SizedBox(height: 12),
                  ..._provider.partners.where((p) => p.isAvailable).map(_buildPartnerCard),
                ],
              ],
            ),
          ),
        );
    }
  }

  Widget _buildBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fuel Delivery', style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary,
          )),
          const SizedBox(height: 4),
          Text('Get fuel delivered to your vehicle anywhere in the city', style: TextStyle(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            fontSize: 13,
          )),
          const SizedBox(height: 16),
          Row(
            children: [
              _bannerChip(theme, Icons.timer_outlined, '15-30 min'),
              const SizedBox(width: 8),
              _bannerChip(theme, Icons.monetization_on_outlined, '₹29 delivery'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onPrimary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimary)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600));
  }

  Widget _buildFuelTypeGrid(ThemeData theme) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _provider.fuelTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final fuelType = _provider.fuelTypes[i];
          return FuelTypeCard(
            fuelType: fuelType,
            isSelected: _provider.selectedFuelType == fuelType,
            onTap: () => _provider.selectFuelType(fuelType),
          );
        },
      ),
    );
  }

  Widget _buildQuantitySelector(ThemeData theme) {
    return QuantitySelector(
      quantity: _provider.quantity,
      onChanged: _provider.setQuantity,
    );
  }

  Widget _buildSearchButton(ThemeData theme) {
    return FuelActionButton(
      label: 'Search Partners',
      icon: Icons.search_rounded,
      onTap: () => _provider.runSearch(),
      isLoading: _provider.isSearching,
    );
  }

  Widget _buildPartnerCard(FuelPartner partner) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(partner.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        title: Text(partner.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${partner.vehicleModel} • ${partner.distance.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${partner.etaMinutes} min', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            Text('${partner.ratingCount} ratings', style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
