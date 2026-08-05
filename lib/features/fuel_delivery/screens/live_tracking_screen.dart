import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/fuel_provider.dart';
import '../utils/location_utils.dart';
import '../widgets/widgets.dart';
import 'order_complete_screen.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  bool _navigated = false;
  late final FuelProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<FuelProvider>();
    final order = _provider.activeOrder;
    if (order != null && !order.status.isTerminal) {
      _provider.startTracking(order.id);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _provider.stopTracking();
    super.dispose();
  }

  void _onOrderCompleted(FuelOrder order) {
    if (_navigated) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrderCompleteScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FuelProvider>();
    final order = provider.activeOrder;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Tracking')),
        body: Center(
          child: TextButton(
            onPressed:
                () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('Back to Home'),
          ),
        ),
      );
    }

    if (order.status == OrderStatus.delivered && !_navigated) {
      _onOrderCompleted(order);
    }

    if (order.status == OrderStatus.cancelled && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      });
    }

    final tracking = provider.trackingInfo;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        title: const Text('Live Tracking'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: () {
              final partner = order.partner;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    partner != null
                        ? 'Calling ${partner.name}...'
                        : 'No delivery partner assigned yet',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Call Partner',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(flex: 3, child: _buildMap(context, order, tracking)),
          _buildBottomPanel(context, order, tracking),
        ],
      ),
    );
  }

  Widget _buildMap(
    BuildContext context,
    FuelOrder order,
    TrackingInfo? tracking,
  ) {
    final theme = Theme.of(context);
    final customerLat =
        tracking?.customerLatitude ?? order.deliveryLocation.latitude;
    final customerLon =
        tracking?.customerLongitude ?? order.deliveryLocation.longitude;
    final partnerLat = tracking?.partnerLatitude ?? customerLat + 0.005;
    final partnerLon = tracking?.partnerLongitude ?? customerLon + 0.003;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          (customerLat + partnerLat) / 2,
          (customerLon + partnerLon) / 2,
        ),
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.mecha_connect.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(partnerLat, partnerLon),
              width: 80,
              height: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        tracking != null
                            ? Text(
                              '${tracking.etaMinutes} min',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 10,
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    Icons.local_shipping_rounded,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                ],
              ),
            ),
            Marker(
              point: LatLng(customerLat, customerLon),
              width: 40,
              height: 40,
              child: Icon(
                Icons.location_on_rounded,
                color: AppColors.brandOrange,
                size: 36,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomPanel(
    BuildContext context,
    FuelOrder order,
    TrackingInfo? tracking,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 420),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    order.status.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Refresh tracking',
                    onPressed:
                        () => context.read<FuelProvider>().startTracking(
                          order.id,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TrackingTimeline(status: order.status),
              const SizedBox(height: 16),
              if (tracking != null)
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        context,
                        Icons.timer_outlined,
                        'ETA',
                        Text(
                          '${tracking.etaMinutes} min',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statCard(
                        context,
                        Icons.map_rounded,
                        'Distance',
                        Text(
                          formatDistance(tracking.distanceRemaining),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statCard(
                        context,
                        Icons.speed_rounded,
                        'Time',
                        _ElapsedTimerText(),
                      ),
                    ),
                  ],
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showOrderDetails(context, order),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text(
                    'View Order Details',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (!order.status.isTerminal)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _cancelOrder(context),
                    child: Text(
                      'Cancel Order',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    IconData icon,
    String label,
    Widget value,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          value,
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, FuelOrder order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      ctx,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Order Details',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _detailItem(ctx, 'Order ID', order.id),
                _detailItem(
                  ctx,
                  'Fuel',
                  '${order.fuelType.name} • ${order.quantity.toInt()}L',
                ),
                _detailItem(ctx, 'Vehicle', order.vehicle.summary),
                _detailItem(ctx, 'Station', order.station?.name ?? '—'),
                _detailItem(ctx, 'Delivery', order.deliveryLocation.address),
                _detailItem(
                  ctx,
                  'Total',
                  '₹${order.priceEstimate.grandTotal.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
    );
  }

  Widget _detailItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: context.textTertiary),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelOrder(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Cancel Order?'),
            content: const Text(
              'Are you sure you want to cancel this fuel delivery order?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await context.read<FuelProvider>().cancelOrder();
                  if (context.mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error,
                ),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );
  }
}

/// Self-contained ticking clock. Keeps the 1s timer isolated so the whole
/// tracking screen (including the map) does not rebuild every second.
class _ElapsedTimerText extends StatefulWidget {
  @override
  State<_ElapsedTimerText> createState() => _ElapsedTimerTextState();
}

class _ElapsedTimerTextState extends State<_ElapsedTimerText> {
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    final text =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
