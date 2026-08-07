import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:mecha_connect/parts/order_data.dart';
import '../models/models.dart';
import '../repositories/marketplace_repository.dart';
import '../services/cart_service.dart';

enum MarketplaceScreenState { initial, loading, ready, error }

/// How the visible product list is ordered.
enum SortOption {
  newest,
  priceLowToHigh,
  priceHighToLow,
  bestRated,
  popularity;

  String get label {
    switch (this) {
      case SortOption.newest:
        return 'Newest';
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.priceHighToLow:
        return 'Price: High to Low';
      case SortOption.bestRated:
        return 'Best Rated';
      case SortOption.popularity:
        return 'Popularity';
    }
  }
}

/// Single source of truth for the Marketplace module.
///
/// Owns the catalog, browse/filter/sort state, cart, wishlist, recently viewed,
/// coupon and checkout lifecycle. Screens render provider state and call
/// methods here — they never keep their own copies of marketplace data.
class MarketplaceProvider extends ChangeNotifier {
  final MarketplaceRepository _repository;
  final CartService _cartService;

  MarketplaceProvider({
    MarketplaceRepository? repository,
    CartService? cartService,
  })  : _repository = repository ?? MarketplaceRepository(),
        _cartService = cartService ?? CartService();

  // ── UI state ──────────────────────────────────────────────────────────
  MarketplaceScreenState _state = MarketplaceScreenState.initial;
  MarketplaceScreenState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  // ── Catalog ───────────────────────────────────────────────────────────
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Brand> _brands = [];
  List<Offer> _offers = [];

  List<Product> get products => List.unmodifiable(_products);
  List<Category> get categories => List.unmodifiable(_categories);
  List<Brand> get brands => List.unmodifiable(_brands);
  List<Offer> get offers => List.unmodifiable(_offers);
  List<Coupon> get coupons => _repository.getCoupons();

  // ── Browse / filter / sort (provider-owned) ───────────────────────────
  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  Category? get selectedCategory {
    for (final c in _categories) {
      if (c.id == _selectedCategoryId) return c;
    }
    return null;
  }

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  final Set<String> _selectedBrands = {};
  Set<String> get selectedBrands => Set.unmodifiable(_selectedBrands);

  double? _minPrice;
  double? _maxPrice;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;

  bool _inStockOnly = false;
  bool get inStockOnly => _inStockOnly;

  double _minRating = 0;
  double get minRating => _minRating;

  final Set<VehicleType> _selectedVehicleTypes = {};
  Set<VehicleType> get selectedVehicleTypes =>
      Set.unmodifiable(_selectedVehicleTypes);

  SortOption _sortOption = SortOption.popularity;
  SortOption get sortOption => _sortOption;

  bool get hasActiveFilters =>
      _selectedCategoryId != null ||
      _searchQuery.trim().isNotEmpty ||
      _selectedBrands.isNotEmpty ||
      _minPrice != null ||
      _maxPrice != null ||
      _inStockOnly ||
      _minRating > 0 ||
      _selectedVehicleTypes.isNotEmpty ||
      _sortOption != SortOption.popularity;

  // ── Recently viewed ───────────────────────────────────────────────────
  final List<Product> _recentlyViewed = [];
  List<Product> get recentlyViewed => List.unmodifiable(_recentlyViewed);

  // ── Cart / coupon ─────────────────────────────────────────────────────
  final List<CartItem> _cart = [];
  List<CartItem> get cart => List.unmodifiable(_cart);

  int get cartCount => _cart.fold<int>(0, (sum, c) => sum + c.quantity);
  bool get canCheckout => _cart.isNotEmpty;

  Coupon? _appliedCoupon;
  Coupon? get appliedCoupon => _appliedCoupon;

  PriceSummary get priceSummary =>
      _cartService.calculate(_cart, coupon: _appliedCoupon);

  /// Price summary for a single product+quantity (used by the product page
  /// sticky bar before the item is added to the cart).
  PriceSummary priceSummaryForProduct(Product product, {int quantity = 1}) {
    return _cartService.calculate([
      CartItem(product: product, quantity: quantity),
    ]);
  }

  /// Products from the same category first (same brand ranked higher), then
  /// popular products from other categories to fill the rail.
  List<Product> relatedProducts(Product product, {int limit = 10}) {
    final sameCategory = _products
        .where((p) => p.id != product.id && p.categoryId == product.categoryId)
        .toList()
      ..sort((a, b) {
        final sameBrandA = a.brandId == product.brandId ? 1 : 0;
        final sameBrandB = b.brandId == product.brandId ? 1 : 0;
        if (sameBrandA != sameBrandB) return sameBrandB.compareTo(sameBrandA);
        return b.popularity.compareTo(a.popularity);
      });

    final result = [...sameCategory];
    if (result.length < limit) {
      final others = _products
          .where((p) => p.id != product.id && p.categoryId != product.categoryId)
          .toList()
        ..sort((a, b) => b.popularity.compareTo(a.popularity));
      result.addAll(others.take(limit - result.length));
    }
    return result.take(limit).toList();
  }

  // ── Wishlist ──────────────────────────────────────────────────────────
  final List<WishlistItem> _wishlist = [];
  List<WishlistItem> get wishlist => List.unmodifiable(_wishlist);

  // ── Selected product ──────────────────────────────────────────────────
  Product? _selectedProduct;
  Product? get selectedProduct => _selectedProduct;

  // ── Checkout ──────────────────────────────────────────────────────────
  bool _isPlacingOrder = false;
  bool get isPlacingOrder => _isPlacingOrder;

  final List<String> _lastOrderIds = [];
  List<String> get lastOrderIds => List.unmodifiable(_lastOrderIds);

  double _lastOrderTotal = 0;
  double get lastOrderTotal => _lastOrderTotal;

  String? _checkoutAddress;
  String? get checkoutAddress => _checkoutAddress;

  String? _checkoutPayment;
  String? get checkoutPayment => _checkoutPayment;

  // ── Boot ──────────────────────────────────────────────────────────────

  /// Loads the whole catalog in parallel (products, categories, brands,
  /// offers) so the home page is interactive in a single 700ms round-trip.
  Future<void> load() async {
    if (_state == MarketplaceScreenState.loading) return;
    _state = MarketplaceScreenState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final (products, categories, brands, offers) = await (
        _repository.fetchProducts(),
        _repository.fetchCategories(),
        _repository.fetchBrands(),
        _repository.fetchOffers(),
      ).wait;

      _products = products;
      _categories = categories;
      _brands = brands;
      _offers = offers;

      _state = MarketplaceScreenState.ready;
    } catch (e) {
      _state = MarketplaceScreenState.error;
      _errorMessage = 'Could not load the marketplace. Pull to retry.';
    }
    notifyListeners();
  }

  /// Re-fetches the catalog without flipping the UI into the loading state,
  /// so a pull-to-refresh never blanks the home page to the skeleton (same
  /// behaviour as the Fuel module's refresh: content stays visible while the
  /// data refreshes in place).
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();

    try {
      final (products, categories, brands, offers) = await (
        _repository.fetchProducts(),
        _repository.fetchCategories(),
        _repository.fetchBrands(),
        _repository.fetchOffers(),
      ).wait;

      _products = products;
      _categories = categories;
      _brands = brands;
      _offers = offers;

      _state = MarketplaceScreenState.ready;
    } catch (e) {
      _errorMessage = 'Could not refresh the marketplace. Pull to retry.';
      // Never tear down a page the user can already see: a failed pull-to-
      // refresh keeps the loaded content and the last-known-good state.
      if (_state != MarketplaceScreenState.ready) {
        _state = MarketplaceScreenState.error;
      }
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // ── Section collections ───────────────────────────────────────────────

  Category? categoryById(String id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Product? productById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Product> productsByCategory(String categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  List<Product> get flashDeals =>
      _products.where((p) => p.isFlashDeal && p.inStock).toList();

  List<Product> get featuredProducts =>
      _products.where((p) => p.isFeatured && p.inStock).toList();

  List<Product> get bestSellers =>
      _products.where((p) => p.isBestSeller && p.inStock).toList();

  List<Product> get trendingProducts =>
      _products.where((p) => p.isTrending && p.inStock).toList();

  List<Product> get recommendedProducts =>
      _products.where((p) => p.isRecommended).toList();

  // ── Browse / filters / sort ───────────────────────────────────────────

  /// The filtered + sorted product list rendered by every browse grid.
  List<Product> get visibleProducts {
    final list = _products.where(_matches).toList();
    _sort(list);
    return list;
  }

  bool _matches(Product p) {
    if (_selectedCategoryId != null && p.categoryId != _selectedCategoryId) {
      return false;
    }
    if (_searchQuery.trim().isNotEmpty && !_matchesQuery(p)) return false;
    if (_selectedBrands.isNotEmpty && !_selectedBrands.contains(p.brandId)) {
      return false;
    }
    if (_minPrice != null && p.price < _minPrice!) return false;
    if (_maxPrice != null && p.price > _maxPrice!) return false;
    if (_inStockOnly && !p.inStock) return false;
    if (_minRating > 0 && p.rating < _minRating) return false;
    if (_selectedVehicleTypes.isNotEmpty &&
        !_selectedVehicleTypes.any(p.vehicleTypes.contains)) {
      return false;
    }
    return true;
  }

  bool _matchesQuery(Product p) {
    final q = _searchQuery.trim().toLowerCase();
    final categoryName = _categoryNameOf(p.categoryId);
    return p.name.toLowerCase().contains(q) ||
        p.brand.toLowerCase().contains(q) ||
        categoryName.toLowerCase().contains(q);
  }

  String _categoryNameOf(String categoryId) {
    for (final c in _categories) {
      if (c.id == categoryId) return c.name;
    }
    return categoryId;
  }

  void _sort(List<Product> list) {
    switch (_sortOption) {
      case SortOption.newest:
        list.sort((a, b) => a.ageDays.compareTo(b.ageDays));
        break;
      case SortOption.priceLowToHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighToLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.bestRated:
        list.sort((a, b) {
          final byRating = b.rating.compareTo(a.rating);
          if (byRating != 0) return byRating;
          return b.ratingCount.compareTo(a.ratingCount);
        });
        break;
      case SortOption.popularity:
        list.sort((a, b) => b.popularity.compareTo(a.popularity));
        break;
    }
  }

  void selectCategory(Category? category) {
    _selectedCategoryId = category?.id;
    notifyListeners();
  }

  void clearCategory() {
    _selectedCategoryId = null;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleBrand(String brandId) {
    if (!_selectedBrands.add(brandId)) {
      _selectedBrands.remove(brandId);
    }
    notifyListeners();
  }

  /// Replaces the whole brand selection (used by the filter sheet's Apply).
  void setBrands(Set<String> brands) {
    _selectedBrands
      ..clear()
      ..addAll(brands);
    notifyListeners();
  }

  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    notifyListeners();
  }

  void setInStockOnly(bool value) {
    _inStockOnly = value;
    notifyListeners();
  }

  void toggleInStockOnly() {
    _inStockOnly = !_inStockOnly;
    notifyListeners();
  }

  void setMinRating(double rating) {
    _minRating = rating;
    notifyListeners();
  }

  void toggleVehicleType(VehicleType type) {
    if (!_selectedVehicleTypes.add(type)) {
      _selectedVehicleTypes.remove(type);
    }
    notifyListeners();
  }

  /// Replaces the whole vehicle-type selection (used by the filter sheet).
  void setVehicleTypes(Set<VehicleType> types) {
    _selectedVehicleTypes
      ..clear()
      ..addAll(types);
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  /// Resets every browse/filter/sort/search/category selector.
  void resetBrowse() {
    _selectedCategoryId = null;
    _searchQuery = '';
    _selectedBrands.clear();
    _minPrice = null;
    _maxPrice = null;
    _inStockOnly = false;
    _minRating = 0;
    _selectedVehicleTypes.clear();
    _sortOption = SortOption.popularity;
    notifyListeners();
  }

  /// Alias for the "Reset Filters" empty-state action on the home grid.
  void resetFilters() => resetBrowse();

  // ── Product selection / recently viewed ───────────────────────────────

  void openProduct(Product product) {
    _selectedProduct = product;
    _recentlyViewed.removeWhere((p) => p.id == product.id);
    _recentlyViewed.insert(0, product);
    if (_recentlyViewed.length > 10) {
      _recentlyViewed.removeRange(10, _recentlyViewed.length);
    }
    notifyListeners();
  }

  // ── Cart ──────────────────────────────────────────────────────────────

  void addToCart(Product product, {int quantity = 1}) {
    final qty = quantity < 1 ? 1 : quantity;
    final index = _cart.indexWhere((c) => c.product.id == product.id);
    if (index >= 0) {
      _cart[index] = _cart[index].copyWith(quantity: _cart[index].quantity + qty);
    } else {
      _cart.add(CartItem(product: product, quantity: qty));
    }
    notifyListeners();
  }

  int quantityInCart(String productId) {
    final index = _cart.indexWhere((c) => c.product.id == productId);
    return index >= 0 ? _cart[index].quantity : 0;
  }

  void incrementQuantity(String productId) {
    final index = _cart.indexWhere((c) => c.product.id == productId);
    if (index < 0) return;
    final max = _cart[index].product.stock > 0 ? _cart[index].product.stock : 99;
    _cart[index] = _cart[index]
        .copyWith(quantity: (_cart[index].quantity + 1).clamp(1, max));
    notifyListeners();
  }

  /// Sets an exact cart quantity, clamped to [1, stock].
  void setQuantity(String productId, int quantity) {
    final index = _cart.indexWhere((c) => c.product.id == productId);
    if (index < 0) return;
    final max = _cart[index].product.stock > 0 ? _cart[index].product.stock : 99;
    _cart[index] = _cart[index]
        .copyWith(quantity: quantity.clamp(1, max));
    notifyListeners();
  }

  void decrementQuantity(String productId) {
    final index = _cart.indexWhere((c) => c.product.id == productId);
    if (index < 0) return;
    if (_cart[index].quantity <= 1) {
      _cart.removeAt(index);
    } else {
      _cart[index] = _cart[index].copyWith(quantity: _cart[index].quantity - 1);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((c) => c.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _appliedCoupon = null;
    notifyListeners();
  }

  // ── Coupon ────────────────────────────────────────────────────────────

  /// Applies a coupon by code. Returns false when the code is unknown or the
  /// cart doesn't meet the coupon's minimum order value.
  bool applyCoupon(String code) {
    final coupon = _findCoupon(code);
    if (coupon == null) return false;
    final itemsTotal = priceSummary.itemsTotal;
    if (itemsTotal < coupon.minOrderValue) return false;
    _appliedCoupon = coupon;
    notifyListeners();
    return true;
  }

  Coupon? _findCoupon(String code) {
    final normalized = code.trim().toLowerCase();
    for (final c in _repository.getCoupons()) {
      if (c.code.toLowerCase() == normalized) return c;
    }
    return null;
  }

  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  // ── Wishlist ──────────────────────────────────────────────────────────

  bool isWishlisted(String productId) =>
      _wishlist.any((w) => w.product.id == productId);

  void toggleWishlist(Product product) {
    final index = _wishlist.indexWhere((w) => w.product.id == product.id);
    if (index >= 0) {
      _wishlist.removeAt(index);
    } else {
      _wishlist.insert(0, WishlistItem(product: product, addedAt: DateTime.now()));
    }
    notifyListeners();
  }

  void removeFromWishlist(String productId) {
    _wishlist.removeWhere((w) => w.product.id == productId);
    notifyListeners();
  }

  void moveWishlistToCart(String productId) {
    final index = _wishlist.indexWhere((w) => w.product.id == productId);
    if (index < 0) return;
    addToCart(_wishlist[index].product);
    _wishlist.removeAt(index);
    notifyListeners();
  }

  // ── Checkout ──────────────────────────────────────────────────────────

  /// Places the whole cart as marketplace orders and registers them with the
  /// shared Orders tab store. On success the cart and coupon are cleared.
  Future<bool> placeOrder({
    required CheckoutAddress address,
    required String paymentMethod,
  }) async {
    if (_cart.isEmpty || _isPlacingOrder) return false;

    _isPlacingOrder = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = _cart.map((c) {
        final p = c.product;
        return OrderItem(
          productId: p.id,
          name: p.name,
          brand: p.brand,
          imageUrl: p.imageUrl,
          unitPrice: p.price,
          quantity: c.quantity,
        );
      }).toList();

      final summary = priceSummary;
      final orders = await _repository.createOrder(
        items: items,
        address: address.fullAddress,
        paymentMethod: paymentMethod,
      );

      // Register each line in the shared Orders tab store (Orders integration).
      for (final order in orders) {
        addMarketplaceOrder(
          id: order.id,
          name: order.item.name,
          brand: order.item.brand,
          quantity: order.item.quantity,
          price: order.item.unitPrice,
          image: order.item.imageUrl,
        );
      }

      _lastOrderIds
        ..clear()
        ..addAll(orders.map((o) => o.id));
      _lastOrderTotal = summary.grandTotal;
      _checkoutAddress = address.fullAddress;
      _checkoutPayment = paymentMethod;

      _cart.clear();
      _appliedCoupon = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }
}
