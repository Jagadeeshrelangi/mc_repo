import 'dart:math';
import '../models/models.dart';
import '../constants/fuel_constants.dart';

class FuelRepository {
  final List<FuelOrder> _orders = [];
  final Random _random = Random();
  int _orderCounter = 0;

  List<FuelType> getFuelTypes() => FuelType.values;

  PriceEstimate calculatePrice(FuelType fuelType, double quantity) {
    final fuelCost = fuelType.pricePerLitre * quantity;
    final deliveryCharge = FuelConstants.deliveryCharge;
    final platformFee = FuelConstants.platformFee;
    final taxes = (fuelCost + deliveryCharge + platformFee) * FuelConstants.taxRate;
    final grandTotal = fuelCost + deliveryCharge + platformFee + taxes;
    final etaMinutes = 15 + _random.nextInt(16);

    return PriceEstimate(
      fuelCost: fuelCost,
      deliveryCharge: deliveryCharge,
      platformFee: platformFee,
      taxes: taxes,
      grandTotal: grandTotal,
      etaMinutes: etaMinutes,
    );
  }

  List<FuelPartner> getNearbyPartners({required double latitude, required double longitude}) {
    final names = ['Rajesh Kumar', 'Suresh Reddy', 'Amit Singh', 'Vikram Patel', 'Ravi Shankar'];
    final vehicles = ['KA-01-AB-1234', 'KA-02-CD-5678', 'KA-03-EF-9012', 'KA-04-GH-3456', 'KA-05-IJ-7890'];
    final models = ['Tata Ace', 'Mahindra Bolero', 'Ashok Leyland Dost', 'Tata 407', 'Maruti Suzuki Super Carry'];

    return List.generate(5, (i) {
      return FuelPartner(
        id: 'partner_${i + 1}',
        name: names[i],
        phone: '+91 9${_random.nextInt(100000000) + 6000000000}',
        rating: 4.0 + _random.nextDouble(),
        ratingCount: 50 + _random.nextInt(200),
        distance: 1.0 + _random.nextDouble() * 5,
        etaMinutes: 10 + _random.nextInt(20),
        isAvailable: _random.nextBool(),
        vehicleNumber: vehicles[i],
        vehicleModel: models[i],
      );
    });
  }

  Future<FuelOrder> createOrder({
    required FuelType fuelType,
    required double quantity,
    required String vehicleName,
    required String vehicleNumber,
    required DeliveryLocation location,
  }) async {
    _orderCounter++;
    final orderId = 'FUEL-${DateTime.now().year}-${_orderCounter.toString().padLeft(4, '0')}';
    final priceEstimate = calculatePrice(fuelType, quantity);

    final order = FuelOrder(
      id: orderId,
      fuelType: fuelType,
      quantity: quantity,
      deliveryLocation: location,
      priceEstimate: priceEstimate,
      status: OrderStatus.created,
      createdAt: DateTime.now(),
      vehicleName: vehicleName,
      vehicleNumber: vehicleNumber,
    );

    _orders.insert(0, order);
    return order;
  }

  Future<FuelOrder> assignPartner(String orderId) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw Exception('Order not found');

    final partners = getNearbyPartners(latitude: 12.97, longitude: 77.59);
    final partner = partners.firstWhere((p) => p.isAvailable, orElse: () => partners.first);

    final updated = FuelOrder(
      id: _orders[index].id,
      fuelType: _orders[index].fuelType,
      quantity: _orders[index].quantity,
      deliveryLocation: _orders[index].deliveryLocation,
      partner: partner,
      priceEstimate: _orders[index].priceEstimate,
      status: OrderStatus.partnerAssigned,
      invoice: _orders[index].invoice,
      createdAt: _orders[index].createdAt,
      vehicleName: _orders[index].vehicleName,
      vehicleNumber: _orders[index].vehicleNumber,
    );

    _orders[index] = updated;
    return updated;
  }

  Future<FuelOrder> cancelOrder(String orderId) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw Exception('Order not found');

    final updated = FuelOrder(
      id: _orders[index].id,
      fuelType: _orders[index].fuelType,
      quantity: _orders[index].quantity,
      deliveryLocation: _orders[index].deliveryLocation,
      partner: _orders[index].partner,
      priceEstimate: _orders[index].priceEstimate,
      status: OrderStatus.cancelled,
      invoice: _orders[index].invoice,
      createdAt: _orders[index].createdAt,
      vehicleName: _orders[index].vehicleName,
      vehicleNumber: _orders[index].vehicleNumber,
    );

    _orders[index] = updated;
    return updated;
  }

  Future<TrackingInfo> trackOrder(String orderId) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw Exception('Order not found');

    return TrackingInfo(
      partnerLatitude: 12.97 + _random.nextDouble() * 0.01,
      partnerLongitude: 77.59 + _random.nextDouble() * 0.01,
      customerLatitude: _orders[index].deliveryLocation.latitude,
      customerLongitude: _orders[index].deliveryLocation.longitude,
      distanceRemaining: 1.0 + _random.nextDouble() * 3,
      etaMinutes: 5 + _random.nextInt(15),
      status: _orders[index].status,
      statusLabel: _orders[index].status.label,
    );
  }

  List<FuelOrder> getOrderHistory() => List.unmodifiable(_orders);

  FuelOrder? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  Future<Invoice> generateInvoice(String orderId) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw Exception('Order not found');

    final order = _orders[index];
    return Invoice(
      invoiceId: 'INV-${order.id}',
      orderId: order.id,
      createdAt: DateTime.now(),
      fuelType: order.fuelType.name,
      quantity: order.quantity,
      pricePerLitre: order.fuelType.pricePerLitre,
      fuelCost: order.priceEstimate.fuelCost,
      deliveryCharge: order.priceEstimate.deliveryCharge,
      platformFee: order.priceEstimate.platformFee,
      taxes: order.priceEstimate.taxes,
      grandTotal: order.priceEstimate.grandTotal,
      partnerName: order.partner?.name ?? '',
      vehicleNumber: order.vehicleNumber,
    );
  }
}
