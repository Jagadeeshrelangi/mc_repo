import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/fuel_provider.dart';
import '../widgets/widgets.dart';
import 'live_tracking_screen.dart';
import 'receipt_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int _filterIndex = 0;

  static const List<String> _filters = [
    'All',
    'Delivered',
    'In Progress',
    'Cancelled',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FuelOrder> _applyFilters(List<FuelOrder> orders) {
    var result = List<FuelOrder>.from(orders);

    switch (_filterIndex) {
      case 1:
        result =
            result.where((o) => o.status == OrderStatus.delivered).toList();
        break;
      case 2:
        result = result.where((o) => !o.status.isTerminal).toList();
        break;
      case 3:
        result =
            result.where((o) => o.status == OrderStatus.cancelled).toList();
        break;
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result =
          result.where((o) {
            return o.id.toLowerCase().contains(q) ||
                o.fuelType.name.toLowerCase().contains(q) ||
                o.vehicle.number.toLowerCase().contains(q) ||
                o.vehicle.name.toLowerCase().contains(q) ||
                (o.station?.name.toLowerCase().contains(q) ?? false);
          }).toList();
    }

    return result;
  }

  void _showOrderDetails(BuildContext context, FuelOrder order) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        'Order Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        order.status.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
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
                  _detailItem(ctx, 'Payment', order.paymentMethod),
                  _detailItem(
                    ctx,
                    'Total',
                    '₹${order.priceEstimate.grandTotal.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                  const SizedBox(height: 16),
                  if (order.status == OrderStatus.delivered)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReceiptScreen(order: order),
                            ),
                          );
                        },
                        icon: const Icon(Icons.receipt_long_rounded, size: 18),
                        label: const Text('View Receipt'),
                      ),
                    )
                  else if (!order.status.isTerminal)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<FuelProvider>().openOrder(order);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LiveTrackingScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.near_me_rounded, size: 18),
                        label: const Text('Track Order'),
                      ),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _detailItem(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: isBold ? theme.colorScheme.primary : context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<FuelProvider>();
    final orders = _applyFilters(provider.orderHistory);

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        title: const Text('Order History'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by fuel, vehicle, station, order ID',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon:
                    _query.isNotEmpty
                        ? IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final isSelected = _filterIndex == i;
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: 'Filter: ${_filters[i]}',
                  child: GestureDetector(
                    onTap: () => setState(() => _filterIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _filters[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.refreshHistory,
              child:
                  orders.isEmpty
                      ? LayoutBuilder(
                        builder:
                            (context, constraints) => SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: _buildEmptyState(context, provider),
                              ),
                            ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder:
                            (_, i) => RecentOrderCard(
                              order: orders[i],
                              onTap:
                                  () => _showOrderDetails(context, orders[i]),
                            ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, FuelProvider provider) {
    final hasOrders = provider.orderHistory.isNotEmpty;
    return FuelEmptyState(
      icon: hasOrders ? Icons.search_off_rounded : Icons.receipt_long_rounded,
      title: hasOrders ? 'No orders match' : 'No orders yet',
      subtitle:
          hasOrders
              ? 'Try a different search or filter.'
              : 'Your fuel delivery orders will appear here.',
      actionLabel: 'Refresh',
      onAction: provider.refreshHistory,
    );
  }
}
