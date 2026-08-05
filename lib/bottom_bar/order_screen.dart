import 'package:flutter/material.dart';
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

class _OrderscreenState extends State<Orderscreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _tabs = ['All', 'Parts', 'Mechanic', 'Fuel', 'AI'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredOrders {
    var orders = List<Map<String, dynamic>>.from(ordersList);
    if (_searchQuery.isNotEmpty) {
      orders = orders.where((o) =>
        o['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    return orders;
  }

  void _cancelOrder(int index) {
    setState(() {
      ordersList.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Order cancelled'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.bgTertiary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Icon(Icons.search_rounded, color: context.textTertiary, size: 20),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search orders...',
                            hintStyle: TextStyle(color: context.textTertiary, fontSize: 13),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          style: TextStyle(fontSize: 13, color: context.textPrimary),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.close_rounded, size: 18, color: context.textTertiary),
                          ),
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
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
      body: _filteredOrders.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _filteredOrders[index];
                return OrderCard(
                  title: item['name'] ?? 'Order',
                  subtitle: 'Qty: ${item['quantity']} · ${item['brand'] ?? 'Generic'}',
                  status: 'Completed',
                  date: 'Today',
                  total: ((item['price'] as int) * (item['quantity'] as int)).toDouble(),
                  type: OrderType.parts,
                  imageUrl: item['image'],
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order details for ${item['name']} coming soon!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onCancel: () => _cancelOrder(index),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
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
              child: Icon(Icons.receipt_long_rounded, size: 48, color: context.textTertiary),
            ),
            const SizedBox(height: 20),
            Text(
              'No Orders Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Space Grotesk',
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Book a mechanic,\nfuel delivery, or purchase spare parts.',
              style: TextStyle(fontSize: 14, color: context.textTertiary),
              textAlign: TextAlign.center,
            ),
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
        ),
      ),
    );
  }
}
