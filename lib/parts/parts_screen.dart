import 'package:flutter/material.dart';
import 'package:mecha_connect/parts/cart_screen.dart';
import '../widgets/product_card.dart';
import '../widgets/category_chip.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_helpers.dart';

class PartsScreen extends StatefulWidget {
  const PartsScreen({super.key});

  @override
  State<PartsScreen> createState() => _PartsScreenState();
}

class _PartsScreenState extends State<PartsScreen> {
  // ── Vehicle filter ────────────────────────────────────────────────
  final List<String> _vehicleList = ["Bike", "Car", "Other"];
  String? selectedVehicle;

  // ── Search ────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchResults = false;
  final List<String> _recentSearches = [
    'Brake pads', 'Engine oil', 'Chain kit', 'Battery'
  ];
  final List<String> _trendingSearches = [
    'Oil filter', 'Helmet', 'Gloves', 'Phone mount'
  ];

  // ── Categories ────────────────────────────────────────────────────
  String _selectedCategory = 'All';
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Engine', 'icon': Icons.settings_rounded},
    {'name': 'Brakes', 'icon': Icons.stop_circle_rounded},
    {'name': 'Oil', 'icon': Icons.water_drop_rounded},
    {'name': 'Battery', 'icon': Icons.battery_charging_full_rounded},
    {'name': 'Tyres', 'icon': Icons.circle_outlined},
    {'name': 'Lights', 'icon': Icons.lightbulb_outline_rounded},
    {'name': 'Accessories', 'icon': Icons.headphones_rounded},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services_rounded},
    {'name': 'Electronics', 'icon': Icons.devices_rounded},
    {'name': 'Emergency', 'icon': Icons.emergency_rounded},
  ];

  // ── Products data ────────────────────────────────────────────────
  final Map<String, List<Map<String, dynamic>>> allParts = {
    'Bike': [
      {'name': 'Bike Tire', 'image': 'assets/bike tyre.jpg', 'price': 1500, 'brand': 'MRF', 'rating': 4.2, 'reviews': 128, 'category': 'Tyres', 'originalPrice': 1800, 'eta': '2-3 days', 'stock': 'In Stock'},
      {'name': 'Engine Oil', 'image': 'assets/engine oil.png', 'price': 600, 'brand': 'Castrol', 'rating': 4.5, 'reviews': 256, 'category': 'Oil', 'originalPrice': 750, 'eta': '1-2 days', 'stock': 'In Stock'},
      {'name': 'Brake Pads', 'image': 'assets/break pads.png', 'price': 450, 'brand': 'Brembo', 'rating': 4.3, 'reviews': 89, 'category': 'Brakes', 'originalPrice': 550, 'eta': '3-4 days', 'stock': 'In Stock'},
      {'name': 'Chain Kit', 'image': 'assets/chain kit.png', 'price': 500, 'brand': 'Roland', 'rating': 4.1, 'reviews': 67, 'category': 'Engine', 'originalPrice': 650, 'eta': '2-3 days', 'stock': 'Low Stock'},
      {'name': 'Clutch Lever', 'image': 'assets/clutch lever.png', 'price': 1300, 'brand': 'Bajaj', 'rating': 4.0, 'reviews': 45, 'category': 'Accessories', 'originalPrice': 1500, 'eta': '4-5 days', 'stock': 'In Stock'},
      {'name': 'Fuel Tank Cap', 'image': 'assets/fuel tank cap.png', 'price': 400, 'brand': 'TVS', 'rating': 3.9, 'reviews': 34, 'category': 'Accessories', 'originalPrice': 500, 'eta': '1-2 days', 'stock': 'In Stock'},
    ],
    'Car': [
      {'name': 'Car Battery', 'image': 'assets/battery.png', 'price': 5000, 'brand': 'Exide', 'rating': 4.6, 'reviews': 312, 'category': 'Battery', 'originalPrice': 5800, 'eta': '1 day', 'stock': 'In Stock'},
      {'name': 'Side Mirror', 'image': 'assets/side_mirror.png', 'price': 350, 'brand': 'Minda', 'rating': 3.8, 'reviews': 56, 'category': 'Accessories', 'originalPrice': 450, 'eta': '3-4 days', 'stock': 'In Stock'},
      {'name': 'Wiper Blades', 'image': 'assets/wipers.png', 'price': 700, 'brand': 'Bosch', 'rating': 4.4, 'reviews': 189, 'category': 'Accessories', 'originalPrice': 850, 'eta': '1-2 days', 'stock': 'In Stock'},
      {'name': 'Gear Knob', 'image': 'assets/gear knob.png', 'price': 500, 'brand': 'Momo', 'rating': 4.1, 'reviews': 78, 'category': 'Accessories', 'originalPrice': 650, 'eta': '2-3 days', 'stock': 'In Stock'},
      {'name': 'Radiator', 'image': 'assets/radiator.png', 'price': 4000, 'brand': 'Valeo', 'rating': 4.3, 'reviews': 42, 'category': 'Engine', 'originalPrice': 4800, 'eta': '5-7 days', 'stock': 'Low Stock'},
    ],
    'Other': [
      {'name': 'Tool Kit', 'image': 'assets/tool kit.png', 'price': 1200, 'brand': 'Stanley', 'rating': 4.5, 'reviews': 234, 'category': 'Emergency', 'originalPrice': 1500, 'eta': '1-2 days', 'stock': 'In Stock'},
      {'name': 'Helmet Lock', 'image': 'assets/helmet lock.png', 'price': 250, 'brand': 'Studds', 'rating': 4.0, 'reviews': 98, 'category': 'Accessories', 'originalPrice': 350, 'eta': '2-3 days', 'stock': 'In Stock'},
      {'name': 'Car Jack', 'image': 'assets/car jack.png', 'price': 1100, 'brand': 'Bey伯', 'rating': 4.2, 'reviews': 156, 'category': 'Emergency', 'originalPrice': 1400, 'eta': '1-2 days', 'stock': 'In Stock'},
      {'name': 'Dash Camera', 'image': 'assets/Dashboard Camera.png', 'price': 4000, 'brand': 'Apeman', 'rating': 4.4, 'reviews': 287, 'category': 'Electronics', 'originalPrice': 5000, 'eta': '2-3 days', 'stock': 'In Stock'},
      {'name': 'GPS Tracker', 'image': 'assets/gps tracker.png', 'price': 3700, 'brand': 'Letstrack', 'rating': 4.1, 'reviews': 134, 'category': 'Electronics', 'originalPrice': 4500, 'eta': '3-4 days', 'stock': 'In Stock'},
      {'name': 'Spark Plug', 'image': 'assets/spark plugs.png', 'price': 400, 'brand': 'NGK', 'rating': 4.6, 'reviews': 345, 'category': 'Engine', 'originalPrice': 500, 'eta': '1-2 days', 'stock': 'In Stock'},
    ],
  };

  // ── Cart ──────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _cartItems = [];
  final Set<String> _wishlistedItems = {};

  // ── Banner ────────────────────────────────────────────────────────
  int _currentBannerIndex = 0;
  final List<Map<String, dynamic>> _banners = [
    {'title': 'Mega Sale', 'subtitle': 'Up to 40% off on all parts', 'color': AppColors.brandOrange},
    {'title': 'Free Delivery', 'subtitle': 'On orders above ₹999', 'color': AppColors.brandBlue},
    {'title': 'Premium Parts', 'subtitle': 'Genuine OEM components', 'color': AppColors.brandBlueDark},
  ];

  // ── Computed ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredParts {
    List<Map<String, dynamic>> allItems = [];

    if (selectedVehicle == null) {
      allItems = allParts.values.expand((parts) => parts).toList();
    } else if (allParts.containsKey(selectedVehicle)) {
      allItems = allParts[selectedVehicle]!;
    }

    if (_selectedCategory != 'All') {
      allItems = allItems.where((item) => item['category'] == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      allItems = allItems.where((item) =>
        item['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item['brand'].toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return allItems;
  }

  List<Map<String, dynamic>> get _featuredParts {
    return allParts.values.expand((parts) => parts).toList()
      ..sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
  }

  int get _cartCount => _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
  double get _cartTotal => _cartItems.fold(0, (sum, item) => sum + (item['price'] as int) * (item['quantity'] as int));

  // ── Cart operations ──────────────────────────────────────────────
  void _addToCart(Map<String, dynamic> item) {
    final index = _cartItems.indexWhere((e) => e['name'] == item['name']);
    setState(() {
      if (index == -1) {
        _cartItems.add({...item, 'quantity': 1});
      } else {
        _cartItems[index]['quantity'] += 1;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['name']} added to cart'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: _openCart,
        ),
      ),
    );
  }

  void _toggleWishlist(Map<String, dynamic> item) {
    setState(() {
      if (_wishlistedItems.contains(item['name'])) {
        _wishlistedItems.remove(item['name']);
      } else {
        _wishlistedItems.add(item['name']);
      }
    });
  }

  bool _isInCart(Map<String, dynamic> item) {
    return _cartItems.any((e) => e['name'] == item['name']);
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          selecttems: _cartItems,
          onRemove: (item) => setState(() => _cartItems.remove(item)),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildBannerCarousel()),
          SliverToBoxAdapter(child: _buildVehicleFilter()),
          SliverToBoxAdapter(child: _buildCategorySection()),
          SliverToBoxAdapter(child: _buildSectionHeader('Featured', 'See All')),
          SliverToBoxAdapter(child: _buildFeaturedProducts()),
          SliverToBoxAdapter(child: _buildSectionHeader('All Products', '${_filteredParts.length} items')),
          _buildProductGrid(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: _buildFloatingCartButton(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: context.bgSecondary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Parts Store',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Space Grotesk',
          color: context.textPrimary,
        ),
      ),
      actions: [
        // Wishlist
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Wishlist feature coming soon!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: Stack(
            children: [
              Icon(Icons.favorite_border_rounded, color: context.textPrimary),
              if (_wishlistedItems.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_wishlistedItems.length}',
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Cart
        IconButton(
          onPressed: _openCart,
          icon: Stack(
            children: [
              Icon(Icons.shopping_cart_outlined, color: context.textPrimary),
              if (_cartItems.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.brandOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.border, width: 1),
              boxShadow: AppElevation.shadowLow,
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(Icons.search_rounded, color: context.textTertiary, size: 22),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search parts, brands...',
                      hintStyle: TextStyle(color: context.textTertiary, fontSize: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    style: TextStyle(fontSize: 14, color: context.textPrimary),
                    onChanged: (v) => setState(() {
                      _searchQuery = v;
                      _showSearchResults = v.isNotEmpty;
                    }),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _showSearchResults = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.close_rounded, color: context.textTertiary, size: 20),
                    ),
                  ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          // Search suggestions
          if (_showSearchResults) _buildSearchSuggestions(),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSoft),
        boxShadow: AppElevation.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Text('Recent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textTertiary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((s) => _buildSuggestionChip(s)).toList(),
            ),
            const SizedBox(height: 12),
          ],
          Text('Trending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textTertiary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _trendingSearches.map((s) => _buildSuggestionChip(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        setState(() {
          _searchQuery = text;
          _showSearchResults = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.bgTertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.border),
        ),
        child: Text(text, style: TextStyle(fontSize: 12, color: context.textSecondary)),
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _currentBannerIndex = i),
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      banner['color'] as Color,
                      (banner['color'] as Color).withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            banner['title'],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Space Grotesk',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            banner['subtitle'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.local_offer_rounded,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == _currentBannerIndex ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i == _currentBannerIndex ? AppColors.brandOrange : AppColors.grey300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildVehicleFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _buildVehicleChip('All Vehicles', null),
          const SizedBox(width: 8),
          ..._vehicleList.map((v) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildVehicleChip(v, v),
          )),
        ],
      ),
    );
  }

  Widget _buildVehicleChip(String label, String? value) {
    final isSelected = selectedVehicle == value;
    return GestureDetector(
      onTap: () => setState(() => selectedVehicle = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandOrange : context.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.brandOrange : context.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : context.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return CategoryChip(
            label: cat['name'],
            icon: cat['icon'],
            isSelected: _selectedCategory == cat['name'],
            onTap: () => setState(() => _selectedCategory = cat['name']),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Space Grotesk',
                color: context.textPrimary,
              ),
            ),
            if (action.isNotEmpty)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title view coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  action,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandOrange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    final featured = _featuredParts.take(4).toList();
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: featured.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final part = featured[index];
          return SizedBox(
            width: 170,
            child: ProductCard(
              name: part['name'],
              brand: part['brand'],
              imagePath: part['image'],
              price: (part['price'] as int).toDouble(),
              originalPrice: part['originalPrice'] != null ? (part['originalPrice'] as int).toDouble() : null,
              rating: part['rating'],
              reviewCount: part['reviews'],
              deliveryEta: part['eta'],
              stockLabel: part['stock'],
              isWishlisted: _wishlistedItems.contains(part['name']),
              isInCart: _isInCart(part),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Product details for ${part['name']} coming soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onAddToCart: () => _addToCart(part),
              onWishlist: () => _toggleWishlist(part),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_filteredParts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: context.textTertiary),
              const SizedBox(height: 16),
              Text(
                'No products found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters or search',
                style: TextStyle(fontSize: 13, color: context.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.58,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final part = _filteredParts[index];
            return ProductCard(
              name: part['name'],
              brand: part['brand'],
              imagePath: part['image'],
              price: (part['price'] as int).toDouble(),
              originalPrice: part['originalPrice'] != null ? (part['originalPrice'] as int).toDouble() : null,
              rating: part['rating'],
              reviewCount: part['reviews'],
              deliveryEta: part['eta'],
              stockLabel: part['stock'],
              isWishlisted: _wishlistedItems.contains(part['name']),
              isInCart: _isInCart(part),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Product details for ${part['name']} coming soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onAddToCart: () => _addToCart(part),
              onWishlist: () => _toggleWishlist(part),
            );
          },
          childCount: _filteredParts.length,
        ),
      ),
    );
  }

  Widget _buildFloatingCartButton() {
    if (_cartItems.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _openCart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandOrange.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 22),
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.brandOrange),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Text(
              '₹${_cartTotal.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Space Grotesk',
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
