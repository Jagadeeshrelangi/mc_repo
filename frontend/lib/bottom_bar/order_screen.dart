import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/orders/orders.dart';
import 'package:mecha_connect/features/mechanic/screens/rating_review_screen.dart';
import 'package:mecha_connect/parts/order_data.dart';
import '../widgets/order_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_helpers.dart';

class Orderscreen extends StatefulWidget {
  final VoidCallback? onExploreServices;

  const Orderscreen({super.key, this.onExploreServices});

  @override
  State<Orderscreen> createState() => _OrderscreenState();
}

class _OrderscreenState extends State<Orderscreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;

  final List<String> _tabs = ['All', 'Parts', 'Mechanic', 'Fuel', 'AI'];

  late final Listenable _rebuildTrigger;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _rebuildTrigger = Listenable.merge([_tabController, orderStore]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          Provider.of<OrdersProvider>(context, listen: false).loadOrders();
        } catch (_) {}
      }
    });
  }

  void _onTabChanged() {
    try {
      Provider.of<OrdersProvider>(context, listen: false).setTabIndex(_tabController.index);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  OrderType? get _selectedType {
    switch (_tabController.index) {
      case 1:
        return OrderType.parts;
      case 2:
        return OrderType.mechanic;
      case 3:
        return OrderType.fuel;
      case 4:
        return OrderType.aiReport;
      default:
        return null;
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final type = _selectedType;
    var orders =
        ordersList.where((o) {
          if (type != null && o['type'] != type.name) return false;
          if (_searchQuery.isNotEmpty) {
            final haystack =
                '${o['name']} ${o['brand']} ${o['status']}'.toLowerCase();
            if (!haystack.contains(_searchQuery.toLowerCase())) return false;
          }
          return true;
        }).toList();
    orders.sort((a, b) {
      final ia = _statusRank(a['status']);
      final ib = _statusRank(b['status']);
      if (ia != ib) return ia.compareTo(ib);
      return (b['date'] ?? '').toString().compareTo(
        (a['date'] ?? '').toString(),
      );
    });
    return orders;
  }

  int _statusRank(dynamic status) {
    switch (status?.toString()) {
      case 'In Progress':
        return 0;
      case 'Pending':
        return 1;
      case 'Delivered':
        return 2;
      case 'Completed':
        return 3;
      case 'Cancelled':
        return 4;
      default:
        return 5;
    }
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      final provider = Provider.of<OrdersProvider>(context, listen: false);
      await provider.refresh();
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 600));
    }
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _cancelOrder(Map<String, dynamic> order) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Cancel Order?'),
            content: Text(
              'Are you sure you want to cancel "${order['name']}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Keep Order'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  bool cancelled = false;
                  try {
                    final provider = Provider.of<OrdersProvider>(context, listen: false);
                    final uOrder = UnifiedOrder.fromJson(order);
                    cancelled = await provider.cancelOrder(uOrder);
                  } catch (_) {
                    ordersList.removeWhere((o) => _sameOrder(o, order));
                    orderStore.notify();
                    cancelled = true;
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(cancelled ? 'Order cancelled' : 'Could not cancel order'),
                        backgroundColor: cancelled ? AppColors.error : AppColors.brandOrange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Cancel Order',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }

  bool _sameOrder(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a['id'] != null && b['id'] != null) return a['id'] == b['id'];
    return a['name'] == b['name'] &&
        a['brand'] == b['brand'] &&
        a['price'] == b['price'] &&
        a['quantity'] == b['quantity'];
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final total =
        ((order['price'] as int) * (order['quantity'] as int)).toDouble();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.border,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    order['name'].toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Space Grotesk',
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order ID: ${order['id'] ?? '—'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textTertiary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(ctx, 'Status', order['status'].toString()),
                  _buildDetailRow(
                    ctx,
                    'Brand',
                    order['brand']?.toString() ?? 'Generic',
                  ),
                  _buildDetailRow(ctx, 'Quantity', '${order['quantity']}'),
                  _buildDetailRow(
                    ctx,
                    'Placed',
                    order['date']?.toString() ?? 'Today',
                  ),
                  Divider(height: 24, color: ctx.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Space Grotesk',
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (order['type'] == 'mechanic' &&
                      order['status']?.toString().toLowerCase() == 'completed' &&
                      order['id'] != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RatingReviewScreen(
                                bookingId: order['id'].toString(),
                                serviceName: order['name']?.toString(),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.star_rounded, color: Colors.white),
                        label: const Text(
                          'Rate / Review Service',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandOrange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: context.textTertiary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Orders',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Space Grotesk',
            color: context.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order filters coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(Icons.filter_list_rounded, color: context.textSecondary),
            tooltip: 'Filter orders',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.bgTertiary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Icon(
                          Icons.search_rounded,
                          color: context.textTertiary,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search orders...',
                            hintStyle: TextStyle(
                              color: context.textTertiary,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textPrimary,
                          ),
                          onChanged: (v) {
                            setState(() => _searchQuery = v);
                            try {
                              Provider.of<OrdersProvider>(context, listen: false).setSearchQuery(v);
                            } catch (_) {}
                          },
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear search',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: context.textTertiary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            try {
                              Provider.of<OrdersProvider>(context, listen: false).setSearchQuery('');
                            } catch (_) {}
                          },
                        ),
                    ],
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.brandOrange,
                unselectedLabelColor: context.textTertiary,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: AppColors.brandOrange,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: context.divider,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _rebuildTrigger,
        builder: (context, _) {
          OrdersProvider? ordersProvider;
          try {
            ordersProvider = Provider.of<OrdersProvider>(context);
          } catch (_) {}

          final isBusy = _isRefreshing || (ordersProvider?.isLoading ?? false);
          final errorMessage = ordersProvider?.errorMessage;
          final orders = ordersProvider != null
              ? ordersProvider.filteredOrders.map((o) => o.toMap()).toList()
              : _filteredOrders;

          if (isBusy) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brandOrange),
            );
          }

          if (errorMessage != null && orders.isEmpty) {
            return _buildErrorState(errorMessage, () {
              ordersProvider?.loadOrders();
            });
          }

          if (orders.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.brandOrange,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = orders[index];
                    final status = item['status']?.toString() ?? 'Completed';
                    return OrderCard(
                      title: item['name'] ?? 'Order',
                      subtitle:
                          'Qty: ${item['quantity']} · ${item['brand'] ?? 'Generic'}',
                      status: status,
                      date: item['date']?.toString() ?? 'Today',
                      total:
                          ((item['price'] as int) * (item['quantity'] as int))
                              .toDouble(),
                      type: _typeFromString(item['type']),
                      imageUrl: item['image'],
                      onTap: () => _showOrderDetails(item),
                      onCancel:
                          status.toLowerCase() == 'cancelled'
                              ? null
                              : () => _cancelOrder(item),
                    );
                  },
                ),
              );
        },
      ),
    );
  }

  OrderType _typeFromString(dynamic value) {
    switch (value?.toString()) {
      case 'mechanic':
        return OrderType.mechanic;
      case 'fuel':
        return OrderType.fuel;
      case 'aiReport':
        return OrderType.aiReport;
      default:
        return OrderType.parts;
    }
  }

  Widget _buildEmptyState() {
    final isEmptyTab = _selectedType != null && ordersList.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.bgTertiary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEmptyTab
                    ? Icons.search_off_rounded
                    : Icons.receipt_long_rounded,
                size: 48,
                color: context.textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEmptyTab
                  ? 'No ${_tabs[_tabController.index]} Orders'
                  : 'No Orders Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Space Grotesk',
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEmptyTab
                  ? 'No ${_tabs[_tabController.index].toLowerCase()} orders match your search.'
                  : 'Book a mechanic,\nfuel delivery, or purchase spare parts.',
              style: TextStyle(fontSize: 14, color: context.textTertiary),
              textAlign: TextAlign.center,
            ),
            if (!isEmptyTab) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: widget.onExploreServices,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Explore Services',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.bgTertiary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Space Grotesk',
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: context.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
