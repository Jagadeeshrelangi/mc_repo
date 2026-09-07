import 'package:flutter/foundation.dart';
import 'package:mecha_connect/parts/order_data.dart';
import 'package:mecha_connect/widgets/order_card.dart';
import '../models/order_model.dart';
import '../repositories/orders_repository.dart';

/// Provider managing unified cross-domain orders state for the Orders tab.
class OrdersProvider extends ChangeNotifier {
  final OrdersRepository _repository;

  List<UnifiedOrder> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedTabIndex = 0;
  String _searchQuery = '';

  OrdersProvider({required OrdersRepository repository})
      : _repository = repository;

  List<UnifiedOrder> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedTabIndex => _selectedTabIndex;
  String get searchQuery => _searchQuery;

  OrderType? get selectedType {
    switch (_selectedTabIndex) {
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

  List<UnifiedOrder> get filteredOrders {
    final type = selectedType;
    var result = _orders.where((o) {
      if (type != null && o.orderType != type) return false;
      if (_searchQuery.isNotEmpty) {
        final haystack = '${o.name} ${o.brand} ${o.status}'.toLowerCase();
        if (!haystack.contains(_searchQuery.toLowerCase())) return false;
      }
      return true;
    }).toList();

    result.sort((a, b) {
      final ia = _statusRank(a.status);
      final ib = _statusRank(b.status);
      if (ia != ib) return ia.compareTo(ib);
      return b.date.compareTo(a.date);
    });

    return result;
  }

  int _statusRank(String status) {
    switch (status) {
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

  void setTabIndex(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Loads orders from the canonical /api/v1/orders backend service.
  /// Never falls back to fake/sample orders on error or empty response.
  Future<void> loadOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _repository.fetchOrders();
      _orders = fetched;
      _errorMessage = null;
      // Keep legacy shared ordersList in sync so other components remain coherent
      ordersList
        ..clear()
        ..addAll(_orders.map((o) => o.toMap()));
      orderStore.notify();
    } catch (e) {
      _errorMessage = 'Failed to load orders: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pull-to-refresh handler.
  Future<void> refresh() async {
    await loadOrders();
  }

  /// Cancels an order via the repository and updates local lists.
  Future<bool> cancelOrder(UnifiedOrder order) async {
    final success = await _repository.cancelOrder(order.id);
    if (success) {
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: 'Cancelled');
        ordersList
          ..clear()
          ..addAll(_orders.map((o) => o.toMap()));
        orderStore.notify();
        notifyListeners();
      }
      return true;
    }
    return false;
  }
}
