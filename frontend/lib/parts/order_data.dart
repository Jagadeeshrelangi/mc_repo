import 'package:flutter/foundation.dart';
import 'package:mecha_connect/widgets/order_card.dart';

/// Notifies listeners whenever [ordersList] changes so the Orders tab (which
/// stays alive inside the bottom navigation's IndexedStack) rebuilds without
/// needing a tab switch to re-render it.
final OrderStore orderStore = OrderStore();

class OrderStore extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Global in-memory order list.
///
/// Sprint 1.5 Extension: seeded with mock orders so the Orders tab renders
/// content across all tabs (Parts / Mechanic / Fuel / AI). Sprint 2+: replace
/// with a real repository backed by the backend API.
List<Map<String, dynamic>> ordersList = _seedOrders();

int _marketplaceOrderCounter = 0;

/// Registers a Marketplace order line in the shared Orders tab store.
///
/// Sprint 1.8 (Orders integration): called by `MarketplaceProvider.placeOrder`
/// so Marketplace orders appear alongside Parts / Mechanic / Fuel / AI without
/// changing the Orders tab architecture. Sprint 2: the provider persists via
/// the backend while this helper keeps feeding the same list the tab reads.
String addMarketplaceOrder({
  String? id,
  required String name,
  required String brand,
  required int quantity,
  required double price,
  String? image,
}) {
  _marketplaceOrderCounter++;
  final orderId =
      id ??
      'MKP-${DateTime.now().year}-${_marketplaceOrderCounter.toString().padLeft(4, '0')}';
  ordersList.insert(0, {
    'id': orderId,
    'name': name,
    'brand': brand,
    'quantity': quantity,
    'price': price.round(),
    'image': image,
    'type': OrderType.parts.name,
    'status': 'Pending',
    'date': 'Today',
  });
  orderStore.notify();
  return orderId;
}

/// Test/dev helper: restores the seeded order list (removes Marketplace orders
/// created during tests). No-op outside tests.
void resetOrdersList() {
  ordersList
    ..clear()
    ..addAll(_seedOrders());
}

List<Map<String, dynamic>> _seedOrders() {
  return [
    {
      'id': 'ORD-1001',
      'name': 'Brake Pads',
      'brand': 'TVS',
      'quantity': 2,
      'price': 699,
      'image': null,
      'type': OrderType.parts.name,
      'status': 'Delivered',
      'date': 'Today',
    },
    {
      'id': 'ORD-1002',
      'name': 'Engine Oil Change',
      'brand': 'Castrol',
      'quantity': 1,
      'price': 899,
      'image': null,
      'type': OrderType.mechanic.name,
      'status': 'Completed',
      'date': 'Yesterday',
    },
    {
      'id': 'ORD-1003',
      'name': 'Fuel Delivery · 5L Petrol',
      'brand': 'Indian Oil',
      'quantity': 1,
      'price': 500,
      'image': null,
      'type': OrderType.fuel.name,
      'status': 'Delivered',
      'date': '2 days ago',
    },
    {
      'id': 'ORD-1004',
      'name': 'AI Diagnosis Report',
      'brand': 'Mecha AI',
      'quantity': 1,
      'price': 299,
      'image': null,
      'type': OrderType.aiReport.name,
      'status': 'Completed',
      'date': '3 days ago',
    },
    {
      'id': 'ORD-1005',
      'name': 'Clutch Cable Replacement',
      'brand': 'Hero',
      'quantity': 1,
      'price': 650,
      'image': null,
      'type': OrderType.mechanic.name,
      'status': 'In Progress',
      'date': 'Today',
    },
    {
      'id': 'ORD-1006',
      'name': 'Air Filter',
      'brand': 'Bosch',
      'quantity': 1,
      'price': 450,
      'image': null,
      'type': OrderType.parts.name,
      'status': 'Cancelled',
      'date': '4 days ago',
    },
    {
      'id': 'ORD-1007',
      'name': 'Helmet',
      'brand': 'Studds',
      'quantity': 1,
      'price': 1499,
      'image': null,
      'type': OrderType.parts.name,
      'status': 'Pending',
      'date': 'Today',
    },
  ];
}
