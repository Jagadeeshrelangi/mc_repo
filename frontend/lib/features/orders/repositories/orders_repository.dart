import '../models/order_model.dart';
import 'package:mecha_connect/services/api_client.dart';

/// Repository for the Canonical Unified Orders & Activity API (/api/v1/orders/*).
class OrdersRepository {
  final ApiClient? _apiClient;
  final List<UnifiedOrder>? _mockOrders;

  OrdersRepository({
    ApiClient? apiClient,
    List<UnifiedOrder>? mockOrders,
  })  : _apiClient = apiClient,
        _mockOrders = mockOrders != null ? List<UnifiedOrder>.from(mockOrders) : null;

  /// Fetches unified orders for the authenticated user, optionally filtered by type/status.
  /// Never falls back to fake/sample data in production.
  Future<List<UnifiedOrder>> fetchOrders({String? type, String? status}) async {
    final mockOrders = _mockOrders;
    if (mockOrders != null) {
      return mockOrders.where((o) {
        if (type != null && type.isNotEmpty && type.toLowerCase() != 'all') {
          if (o.type.toLowerCase() != type.toLowerCase()) return false;
        }
        if (status != null && status.isNotEmpty) {
          if (o.status.toLowerCase() != status.toLowerCase()) return false;
        }
        return true;
      }).toList();
    }

    final client = _apiClient;
    if (client == null) {
      return [];
    }

    final queryParams = <String>[];
    if (type != null && type.isNotEmpty && type.toLowerCase() != 'all') {
      queryParams.add('type=${Uri.encodeComponent(type)}');
    }
    if (status != null && status.isNotEmpty) {
      queryParams.add('status=${Uri.encodeComponent(status)}');
    }
    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

    final res = await client.get('/api/v1/orders$queryString', requiresAuth: true);
    if (res is List) {
      return res
          .whereType<Map<String, dynamic>>()
          .map((json) => UnifiedOrder.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Fetches detail for a single order by ID.
  Future<UnifiedOrder?> fetchOrderById(String orderId) async {
    final mockOrders = _mockOrders;
    if (mockOrders != null) {
      try {
        return mockOrders.firstWhere((o) => o.id == orderId);
      } catch (_) {
        return null;
      }
    }

    final client = _apiClient;
    if (client == null) return null;

    final res = await client.get('/api/v1/orders/$orderId', requiresAuth: true);
    if (res is Map<String, dynamic>) {
      return UnifiedOrder.fromJson(res);
    }
    return null;
  }

  /// Cancels an order by ID via the backend.
  Future<bool> cancelOrder(String orderId) async {
    final mockOrders = _mockOrders;
    if (mockOrders != null) {
      final index = mockOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        mockOrders[index] = mockOrders[index].copyWith(status: 'Cancelled');
        return true;
      }
      return false;
    }

    final client = _apiClient;
    if (client == null) return false;

    final res = await client.post('/api/v1/orders/$orderId/cancel', requiresAuth: true);
    if (res is Map<String, dynamic> && res['status'] == 'Cancelled') {
      return true;
    }
    return false;
  }
}
