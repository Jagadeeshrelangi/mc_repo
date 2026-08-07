import 'dart:math';
import '../models/models.dart';
import '../services/fuel_service.dart';

/// Mock fuel-delivery API.
///
/// Backend integration lands in Sprint 2; this repository simulates latency
/// and state transitions so the UI behaves exactly like the production flow.
class FuelRepository {
  final FuelService _service = FuelService();
  final Random _random = Random();
  final List<FuelOrder> _orders = [];
  int _orderCounter = 0;

  static const Duration _latency = Duration(milliseconds: 700);

  FuelRepository() {
    _seedHistory();
  }

  Future<void> _delay() => Future<void>.delayed(_latency);

  // ── Types / Vehicles ──────────────────────────────────────────────────

  /// All fuel types, including coming-soon options that render as disabled
  /// cards (Electric Charging, CNG).
  List<FuelType> getFuelTypes() => FuelType.values;

  /// Mock saved vehicles from the user profile. Falls back to this set when
  /// no persisted profile exists (Sprint 2 wires real profile data).
  Future<List<FuelVehicle>> getSavedVehicles() async {
    await _delay();
    return const [
      FuelVehicle(id: 'v1', type: VehicleType.car, name: 'Honda City', number: 'KA-01-AB-1234'),
      FuelVehicle(id: 'v2', type: VehicleType.bike, name: 'Activa 6G', number: 'KA-02-CD-5678'),
      FuelVehicle(id: 'v3', type: VehicleType.suv, name: 'Hyundai Creta', number: 'KA-03-EF-9012'),
    ];
  }

  // ── Stations ──────────────────────────────────────────────────────────

  Future<List<FuelStation>> getFuelStations({
    required double latitude,
    required double longitude,
  }) async {
    await _delay();
    return _buildStations(latitude, longitude);
  }

  List<FuelStation> _buildStations(double lat, double lng) {
    final brands = [
      ('Indian Oil', 'IO'),
      ('Bharat Petroleum', 'BPCL'),
      ('HP Petrol', 'HP'),
      ('Reliance Fuel', 'RL'),
      ('Shell', 'SH'),
      ('Nayara Energy', 'NY'),
    ];
    final names = [
      'Main Road Filling Station',
      'Ring Road Fuels',
      'City Petrol Point',
      'Green Valley Fuel',
      'Highway Fuel Stop',
      'Lake View Petrol Bunk',
    ];
    final addresses = [
      '12, MG Road, Bengaluru',
      '45, Ring Road, Bengaluru',
      '8, K.R. Puram Main Road',
      '3, Green Valley Layout',
      'NH-44, Outer Ring Road',
      '21, Lake View Street',
    ];

    return List.generate(6, (i) {
      final isOpen = i != 4;
      final availability = i == 5
          ? FuelAvailability.outOfStock
          : (i == 2 ? FuelAvailability.low : FuelAvailability.available);
      return FuelStation(
        id: 'station_${i + 1}',
        name: names[i],
        brand: brands[i].$1,
        rating: 4.0 + (_random.nextDouble() * 0.9),
        ratingCount: 120 + _random.nextInt(1800),
        distanceKm: (0.6 + _random.nextDouble() * 6.5),
        etaMinutes: 8 + _random.nextInt(20),
        pricePerLitre: 96.5 + _random.nextDouble() * 6,
        availability: availability,
        isOpen: isOpen,
        address: addresses[i],
      );
    })..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  // ── Orders ────────────────────────────────────────────────────────────

  Future<FuelOrder> createOrder({
    required FuelType fuelType,
    required double quantity,
    required FuelVehicle vehicle,
    required DeliveryLocation location,
    required FuelStation station,
  }) async {
    await _delay();
    _orderCounter++;
    final orderId = 'FUEL-${DateTime.now().year}-${_orderCounter.toString().padLeft(4, '0')}';
    final estimate = _service.calculatePrice(
      fuelType,
      quantity,
      pricePerLitre: station.pricePerLitre,
      etaMinutes: station.etaMinutes,
    );

    final order = FuelOrder(
      id: orderId,
      fuelType: fuelType,
      quantity: quantity,
      deliveryLocation: location,
      station: station,
      vehicle: vehicle,
      priceEstimate: estimate,
      status: OrderStatus.requested,
      createdAt: DateTime.now(),
    );

    _orders.insert(0, order);
    return order;
  }

  Future<FuelOrder> acceptOrder(String orderId) async {
    await _delay();
    return _updateStatus(orderId, OrderStatus.accepted);
  }

  /// Advances the order to the next tracking state in sequence.
  ///
  /// Returns the updated order, or `null` when the order is terminal.
  Future<FuelOrder?> advanceStatus(String orderId) async {
    final index = _indexOf(orderId);
    if (index == -1) return null;

    final order = _orders[index];
    if (order.status.isTerminal) return order;

    final sequence = [
      OrderStatus.requested,
      OrderStatus.accepted,
      OrderStatus.fuelPacked,
      OrderStatus.partnerAssigned,
      OrderStatus.enRoute,
      OrderStatus.arrived,
      OrderStatus.delivered,
    ];
    final current = sequence.indexOf(order.status);
    if (current == -1 || current >= sequence.length - 1) return order;

    final next = sequence[current + 1];
    var updated = order.copyWith(status: next);
    if (next == OrderStatus.partnerAssigned) {
      updated = updated.copyWith(partner: _randomPartner());
    }
    _orders[index] = updated;
    return updated;
  }

  Future<FuelOrder> cancelOrder(String orderId) async {
    await _delay();
    return _updateStatus(orderId, OrderStatus.cancelled);
  }

  Future<FuelOrder> completeOrder(String orderId) async {
    final index = _indexOf(orderId);
    if (index == -1) throw Exception('Order not found');

    final order = _orders[index];
    final invoice = await generateInvoice(orderId);
    final updated = order.copyWith(status: OrderStatus.delivered, invoice: invoice);
    _orders[index] = updated;
    return updated;
  }

  Future<Invoice> generateInvoice(String orderId) async {
    await _delay();
    final order = getOrderById(orderId);
    if (order == null) throw Exception('Order not found');
    final estimate = order.priceEstimate;

    return Invoice(
      invoiceId: 'INV-${order.id}',
      orderId: order.id,
      createdAt: order.createdAt,
      fuelType: order.fuelType.name,
      quantity: order.quantity,
      pricePerLitre: estimate.fuelCost / order.quantity,
      fuelCost: estimate.fuelCost,
      deliveryCharge: estimate.deliveryCharge,
      platformFee: estimate.platformFee,
      taxes: estimate.taxes,
      grandTotal: estimate.grandTotal,
      partnerName: order.partner?.name ?? '',
      vehicleNumber: order.vehicle.number,
    );
  }

  Future<TrackingInfo> getTracking(String orderId) async {
    final order = getOrderById(orderId);
    if (order == null) throw Exception('Order not found');
    await _delay();

    final destination = order.deliveryLocation;
    final distance = order.status.index == 0
        ? 1.0 + _random.nextDouble() * 2
        : max(0.0, order.status.index * 0.9 - _random.nextDouble() * 0.4);
    final eta = max(2, order.priceEstimate.etaMinutes - order.status.index * 2);

    return TrackingInfo(
      partnerLatitude: destination.latitude + 0.003 + _random.nextDouble() * 0.01,
      partnerLongitude: destination.longitude + 0.002 + _random.nextDouble() * 0.01,
      customerLatitude: destination.latitude,
      customerLongitude: destination.longitude,
      distanceRemaining: distance,
      etaMinutes: eta,
      status: order.status,
      statusLabel: order.status.label,
    );
  }

  // ── History / Lookup ──────────────────────────────────────────────────

  List<FuelOrder> getOrderHistory() => List.unmodifiable(_orders);

  FuelOrder? getOrderById(String orderId) {
    final index = _indexOf(orderId);
    return index == -1 ? null : _orders[index];
  }

  Future<List<FuelOrder>> refreshHistory() async {
    await _delay();
    return List.unmodifiable(_orders);
  }

  // ── Internals ─────────────────────────────────────────────────────────

  int _indexOf(String orderId) => _orders.indexWhere((o) => o.id == orderId);

  Future<FuelOrder> _updateStatus(String orderId, OrderStatus status) async {
    final index = _indexOf(orderId);
    if (index == -1) throw Exception('Order not found');
    final updated = _orders[index].copyWith(status: status);
    _orders[index] = updated;
    return updated;
  }

  FuelPartner _randomPartner() {
    const names = ['Rajesh Kumar', 'Suresh Reddy', 'Amit Singh', 'Vikram Patel'];
    const vehicles = ['KA-01-AB-1234', 'KA-02-CD-5678', 'KA-03-EF-9012', 'KA-04-GH-3456'];
    const models = ['Tata Ace', 'Mahindra Bolero', 'Ashok Leyland Dost', 'Maruti Super Carry'];
    final i = _random.nextInt(4);
    return FuelPartner(
      id: 'partner_${i + 1}',
      name: names[i],
      phone: '+91 9${_random.nextInt(100000000) + 6000000000}',
      rating: 4.0 + _random.nextDouble(),
      ratingCount: 50 + _random.nextInt(200),
      distance: 1.0 + _random.nextDouble() * 3,
      etaMinutes: 10 + _random.nextInt(15),
      isAvailable: true,
      vehicleNumber: vehicles[i],
      vehicleModel: models[i],
    );
  }

  void _seedHistory() {
    final now = DateTime.now();
    final stationA = FuelStation(
      id: 'station_1',
      name: 'Main Road Filling Station',
      brand: 'Indian Oil',
      rating: 4.6,
      ratingCount: 1234,
      distanceKm: 1.2,
      etaMinutes: 12,
      pricePerLitre: 98.5,
      availability: FuelAvailability.available,
      isOpen: true,
      address: '12, MG Road, Bengaluru',
    );
    final stationB = FuelStation(
      id: 'station_2',
      name: 'Ring Road Fuels',
      brand: 'BPCL',
      rating: 4.3,
      ratingCount: 890,
      distanceKm: 2.4,
      etaMinutes: 16,
      pricePerLitre: 97.9,
      availability: FuelAvailability.available,
      isOpen: true,
      address: '45, Ring Road, Bengaluru',
    );
    const vehicle = FuelVehicle(
      id: 'v1',
      type: VehicleType.car,
      name: 'Honda City',
      number: 'KA-01-AB-1234',
    );
    const location = DeliveryLocation(
      latitude: 12.9716,
      longitude: 77.5946,
      address: '12, MG Road, Bengaluru',
      label: 'Home',
    );

    void seed({
      required String id,
      required FuelType fuelType,
      required double quantity,
      required FuelStation station,
      required OrderStatus status,
      required String paymentMethod,
      DateTime? createdAt,
    }) {
      _orderCounter++;
      _orders.add(
        FuelOrder(
          id: id,
          fuelType: fuelType,
          quantity: quantity,
          deliveryLocation: location,
          station: station,
          vehicle: vehicle,
          partner: status == OrderStatus.partnerAssigned ||
                  status == OrderStatus.enRoute ||
                  status == OrderStatus.arrived ||
                  status == OrderStatus.delivered
              ? _randomPartner()
              : null,
          priceEstimate: _service.calculatePrice(
            fuelType,
            quantity,
            pricePerLitre: station.pricePerLitre,
            etaMinutes: station.etaMinutes,
          ),
          status: status,
          paymentMethod: paymentMethod,
          createdAt: createdAt ?? now.subtract(Duration(days: _orderCounter)),
        ),
      );
    }

    seed(
      id: 'FUEL-2026-0009',
      fuelType: FuelType.petrol,
      quantity: 5,
      station: stationA,
      status: OrderStatus.delivered,
      paymentMethod: 'UPI',
      createdAt: now.subtract(const Duration(days: 2)),
    );
    seed(
      id: 'FUEL-2026-0008',
      fuelType: FuelType.diesel,
      quantity: 10,
      station: stationB,
      status: OrderStatus.delivered,
      paymentMethod: 'Credit/Debit Card',
      createdAt: now.subtract(const Duration(days: 5)),
    );
    seed(
      id: 'FUEL-2026-0007',
      fuelType: FuelType.premiumPetrol,
      quantity: 3,
      station: stationA,
      status: OrderStatus.cancelled,
      paymentMethod: 'Wallet',
      createdAt: now.subtract(const Duration(days: 8)),
    );
    seed(
      id: 'FUEL-2026-0006',
      fuelType: FuelType.petrol,
      quantity: 2,
      station: stationB,
      status: OrderStatus.delivered,
      paymentMethod: 'Cash on Delivery',
      createdAt: now.subtract(const Duration(days: 12)),
    );
    seed(
      id: 'FUEL-2026-0005',
      fuelType: FuelType.diesel,
      quantity: 5,
      station: stationA,
      status: OrderStatus.cancelled,
      paymentMethod: 'UPI',
      createdAt: now.subtract(const Duration(days: 15)),
    );
  }
}
