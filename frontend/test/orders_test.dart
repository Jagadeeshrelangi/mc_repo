import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/orders/orders.dart';
import 'package:mecha_connect/bottom_bar/order_screen.dart';
import 'package:mecha_connect/parts/order_data.dart';

void main() {
  setUp(() {
    resetOrdersList();
  });

  final sampleOrders = [
    const UnifiedOrder(
      id: 'ORD-1001',
      name: 'Clutch Cable Replacement',
      brand: 'Hero',
      quantity: 1,
      price: 650.0,
      type: 'mechanic',
      status: 'In Progress',
      date: 'Today',
    ),
    const UnifiedOrder(
      id: 'ORD-1002',
      name: 'Helmet',
      brand: 'Studds',
      quantity: 1,
      price: 1499.0,
      type: 'parts',
      status: 'Pending',
      date: 'Today',
    ),
    const UnifiedOrder(
      id: 'ORD-1003',
      name: 'Brake Pads',
      brand: 'TVS',
      quantity: 2,
      price: 699.0,
      type: 'parts',
      status: 'Delivered',
      date: 'Today',
    ),
    const UnifiedOrder(
      id: 'ORD-1004',
      name: 'Engine Oil Change',
      brand: 'Castrol',
      quantity: 1,
      price: 899.0,
      type: 'mechanic',
      status: 'Completed',
      date: 'Yesterday',
    ),
    const UnifiedOrder(
      id: 'ORD-1005',
      name: 'Fuel Delivery · 5L Petrol',
      brand: 'Indian Oil',
      quantity: 1,
      price: 500.0,
      type: 'fuel',
      status: 'Delivered',
      date: '2 days ago',
    ),
    const UnifiedOrder(
      id: 'ORD-1006',
      name: 'AI Diagnosis Report',
      brand: 'Mecha AI',
      quantity: 1,
      price: 299.0,
      type: 'aiReport',
      status: 'Completed',
      date: '3 days ago',
    ),
  ];

  group('UnifiedOrder Model Tests', () {
    test('parses fromJson correctly with various fields', () {
      final json = {
        'id': 'ORD-9001',
        'name': 'Spark Plug',
        'brand': 'Bosch',
        'quantity': 4,
        'price': 450.0,
        'type': 'parts',
        'status': 'In Progress',
        'occurred_at': DateTime.now().toIso8601String(),
        'source': 'Marketplace Checkout',
      };

      final order = UnifiedOrder.fromJson(json);
      expect(order.id, 'ORD-9001');
      expect(order.name, 'Spark Plug');
      expect(order.brand, 'Bosch');
      expect(order.quantity, 4);
      expect(order.price, 450.0);
      expect(order.type, 'parts');
      expect(order.orderType, OrderType.parts);
      expect(order.status, 'In Progress');
      expect(order.date, 'Today');
      expect(order.source, 'Marketplace Checkout');
    });

    test('maps domain types to OrderType enum', () {
      expect(UnifiedOrder.fromJson({'type': 'mechanic'}).orderType, OrderType.mechanic);
      expect(UnifiedOrder.fromJson({'type': 'fuel'}).orderType, OrderType.fuel);
      expect(UnifiedOrder.fromJson({'type': 'aiReport'}).orderType, OrderType.aiReport);
      expect(UnifiedOrder.fromJson({'type': 'parts'}).orderType, OrderType.parts);
      expect(UnifiedOrder.fromJson({'type': 'unknown'}).orderType, OrderType.parts);
    });

    test('toMap converts back with all required keys', () {
      const order = UnifiedOrder(
        id: 'FO-999',
        name: 'Fuel Delivery · 5L Petrol',
        brand: 'Indian Oil',
        quantity: 5,
        price: 520.0,
        type: 'fuel',
        status: 'Delivered',
        date: 'Yesterday',
      );

      final map = order.toMap();
      expect(map['id'], 'FO-999');
      expect(map['name'], 'Fuel Delivery · 5L Petrol');
      expect(map['brand'], 'Indian Oil');
      expect(map['quantity'], 5);
      expect(map['price'], 520);
      expect(map['type'], 'fuel');
      expect(map['status'], 'Delivered');
      expect(map['date'], 'Yesterday');
    });
  });

  group('OrdersRepository Tests', () {
    test('fetchOrders returns empty list without falling back to fake orders', () async {
      final repo = OrdersRepository();
      final orders = await repo.fetchOrders();
      expect(orders.isEmpty, true);
    });

    test('fetchOrders returns mock orders when explicitly provided for test', () async {
      final repo = OrdersRepository(mockOrders: sampleOrders);
      final orders = await repo.fetchOrders();
      expect(orders.length, sampleOrders.length);
      expect(orders.first.id, 'ORD-1001');
    });

    test('cancelOrder updates status in mock orders', () async {
      final repo = OrdersRepository(mockOrders: sampleOrders);
      final success = await repo.cancelOrder('ORD-1001');
      expect(success, true);
      final updated = await repo.fetchOrderById('ORD-1001');
      expect(updated?.status, 'Cancelled');
    });
  });

  group('OrdersProvider State Management Tests', () {
    test('initializes empty without substituting fake orders', () {
      final repo = OrdersRepository();
      final provider = OrdersProvider(repository: repo);

      expect(provider.orders.isEmpty, true);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, false);
    });

    test('loadOrders populates genuine orders on success', () async {
      final repo = OrdersRepository(mockOrders: sampleOrders);
      final provider = OrdersProvider(repository: repo);

      await provider.loadOrders();
      expect(provider.orders.length, sampleOrders.length);
      expect(provider.errorMessage, isNull);
    });

    test('loadOrders preserves empty state without fake substitution when backend returns []', () async {
      final repo = OrdersRepository(mockOrders: []);
      final provider = OrdersProvider(repository: repo);

      await provider.loadOrders();
      expect(provider.orders.isEmpty, true);
      expect(provider.errorMessage, isNull);
    });

    test('loadOrders records error and never substitutes fake orders on exception', () async {
      final repo = FailingOrdersRepository();
      final provider = OrdersProvider(repository: repo);

      await provider.loadOrders();
      expect(provider.orders.isEmpty, true);
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('Network failure'));
    });

    test('supports tab index switching and type filtering', () async {
      final repo = OrdersRepository(mockOrders: sampleOrders);
      final provider = OrdersProvider(repository: repo);
      await provider.loadOrders();

      expect(provider.selectedTabIndex, 0);
      expect(provider.selectedType, null);

      // Switch to Parts (tab 1)
      provider.setTabIndex(1);
      expect(provider.selectedType, OrderType.parts);
      for (final o in provider.filteredOrders) {
        expect(o.orderType, OrderType.parts);
      }

      // Switch to Mechanic (tab 2)
      provider.setTabIndex(2);
      expect(provider.selectedType, OrderType.mechanic);
      for (final o in provider.filteredOrders) {
        expect(o.orderType, OrderType.mechanic);
      }

      // Switch to Fuel (tab 3)
      provider.setTabIndex(3);
      expect(provider.selectedType, OrderType.fuel);
      for (final o in provider.filteredOrders) {
        expect(o.orderType, OrderType.fuel);
      }

      // Switch to AI (tab 4)
      provider.setTabIndex(4);
      expect(provider.selectedType, OrderType.aiReport);
      for (final o in provider.filteredOrders) {
        expect(o.orderType, OrderType.aiReport);
      }
    });

    test('filters orders by search query', () async {
      final repo = OrdersRepository(mockOrders: sampleOrders);
      final provider = OrdersProvider(repository: repo);
      await provider.loadOrders();

      provider.setSearchQuery('brake');
      expect(provider.filteredOrders.length, 1);
      expect(provider.filteredOrders.first.name.toLowerCase().contains('brake'), true);

      provider.setSearchQuery('');
      expect(provider.filteredOrders.length, provider.orders.length);
    });

    test('cancels order and updates provider state', () async {
      final repo = OrdersRepository(mockOrders: sampleOrders);
      final provider = OrdersProvider(repository: repo);
      await provider.loadOrders();

      final target = provider.orders.firstWhere((o) => o.id == 'ORD-1001');
      final ok = await provider.cancelOrder(target);
      expect(ok, true);

      final updated = provider.orders.firstWhere((o) => o.id == 'ORD-1001');
      expect(updated.status, 'Cancelled');
    });
  });

  group('Orderscreen Widget Tests', () {
    testWidgets('renders genuine empty state when orders are empty', (tester) async {
      final repo = OrdersRepository(mockOrders: []);
      final provider = OrdersProvider(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OrdersProvider>.value(
            value: provider,
            child: const Orderscreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Orders Yet'), findsOneWidget);
    });

    testWidgets('renders genuine error state with retry button on failure', (tester) async {
      final repo = FailingOrdersRepository();
      final provider = OrdersProvider(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OrdersProvider>.value(
            value: provider,
            child: const Orderscreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Orders'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders Orderscreen with tabs, search bar, and order cards', (tester) async {
      final repo = OrdersRepository(mockOrders: sampleOrders);
      final provider = OrdersProvider(repository: repo);

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OrdersProvider>.value(
            value: provider,
            child: const Orderscreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check AppBar Title
      expect(find.text('My Orders'), findsOneWidget);

      // Check Tabs
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Parts'), findsOneWidget);
      expect(find.text('Mechanic'), findsOneWidget);
      expect(find.text('Fuel'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);

      // Check Search Field
      expect(find.text('Search orders...'), findsOneWidget);

      // Check Order Card contents
      expect(find.text('Brake Pads'), findsOneWidget);
      expect(find.text('Engine Oil Change'), findsOneWidget);
    });

    testWidgets('switching tabs updates displayed order items', (tester) async {
      final repo = OrdersRepository(mockOrders: sampleOrders);
      final provider = OrdersProvider(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OrdersProvider>.value(
            value: provider,
            child: const Orderscreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on 'Fuel' tab
      await tester.tap(find.text('Fuel'));
      await tester.pumpAndSettle();

      // Should show fuel delivery order
      expect(find.textContaining('Fuel Delivery'), findsOneWidget);
      // Brake pads should no longer be visible in fuel tab
      expect(find.text('Brake Pads'), findsNothing);
    });
  });
}

class FailingOrdersRepository extends OrdersRepository {
  @override
  Future<List<UnifiedOrder>> fetchOrders({String? type, String? status}) async {
    throw Exception('Network failure: 503 Service Unavailable');
  }
}
