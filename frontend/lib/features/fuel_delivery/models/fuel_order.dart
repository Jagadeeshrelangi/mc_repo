import 'fuel_type.dart';
import 'delivery_location.dart';
import 'fuel_partner.dart';
import 'fuel_station.dart';
import 'fuel_vehicle.dart';
import 'price_estimate.dart';
import 'order_status.dart';
import 'invoice.dart';

class FuelOrder {
  final String id;
  final FuelType fuelType;
  final double quantity;
  final DeliveryLocation deliveryLocation;
  final FuelStation? station;
  final FuelVehicle vehicle;
  final FuelPartner? partner;
  final PriceEstimate priceEstimate;
  final OrderStatus status;
  final Invoice? invoice;
  final String paymentMethod;
  final DateTime createdAt;

  const FuelOrder({
    required this.id,
    required this.fuelType,
    required this.quantity,
    required this.deliveryLocation,
    this.station,
    required this.vehicle,
    this.partner,
    required this.priceEstimate,
    required this.status,
    this.invoice,
    this.paymentMethod = 'UPI',
    required this.createdAt,
  });

  FuelOrder copyWith({
    OrderStatus? status,
    FuelPartner? partner,
    Invoice? invoice,
    FuelStation? station,
    String? paymentMethod,
  }) {
    return FuelOrder(
      id: id,
      fuelType: fuelType,
      quantity: quantity,
      deliveryLocation: deliveryLocation,
      station: station ?? this.station,
      vehicle: vehicle,
      partner: partner ?? this.partner,
      priceEstimate: priceEstimate,
      status: status ?? this.status,
      invoice: invoice ?? this.invoice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt,
    );
  }

  factory FuelOrder.fromJson(Map<String, dynamic> json) {
    final fuelTypeStr = (json['fuel_type'] as String? ?? 'petrol').toLowerCase();
    FuelType fuelType = FuelType.petrol;
    for (final t in FuelType.values) {
      if (t.name.toLowerCase() == fuelTypeStr || t.toString().split('.').last.toLowerCase() == fuelTypeStr) {
        fuelType = t;
        break;
      }
    }

    final statusStr = (json['status'] as String? ?? 'requested').toLowerCase();
    OrderStatus status = OrderStatus.requested;
    for (final s in OrderStatus.values) {
      if (s.name.toLowerCase() == statusStr || s.toString().split('.').last.toLowerCase() == statusStr) {
        status = s;
        break;
      }
    }

    final vehicleTypeStr = (json['vehicle_type'] as String? ?? 'Car').toLowerCase();
    VehicleType vType = VehicleType.car;
    for (final vt in VehicleType.values) {
      if (vt.label.toLowerCase() == vehicleTypeStr || vt.name.toLowerCase() == vehicleTypeStr) {
        vType = vt;
        break;
      }
    }

    final priceEstimateJson = json['price_estimate'] as Map<String, dynamic>?;
    final priceEstimate = priceEstimateJson != null
        ? PriceEstimate.fromJson(priceEstimateJson)
        : PriceEstimate(
            fuelCost: (json['quantity'] as num?)?.toDouble() != null && (json['price_per_litre'] as num?)?.toDouble() != null
                ? (json['quantity'] as num).toDouble() * (json['price_per_litre'] as num).toDouble()
                : 0.0,
            deliveryCharge: 49.0,
            platformFee: 15.0,
            taxes: 12.0,
            grandTotal: ((json['quantity'] as num?)?.toDouble() ?? 0.0) * ((json['price_per_litre'] as num?)?.toDouble() ?? 100.0) + 76.0,
            etaMinutes: 15,
          );

    final invoiceJson = json['invoice'] as Map<String, dynamic>?;
    final invoice = invoiceJson != null ? Invoice.fromJson(invoiceJson) : null;

    final location = DeliveryLocation(
      latitude: (json['lat'] as num?)?.toDouble() ?? 12.9716,
      longitude: (json['lng'] as num?)?.toDouble() ?? 77.5946,
      address: json['delivery_address'] as String? ?? '',
      label: json['delivery_label'] as String? ?? 'Home',
    );

    final vehicle = FuelVehicle(
      id: json['vehicle_id'] as String? ?? 'v1',
      type: vType,
      name: json['vehicle_name'] as String? ?? 'Vehicle',
      number: json['vehicle_number'] as String? ?? '',
    );

    FuelStation? station;
    if (json['station_id'] != null || json['station_name'] != null) {
      station = FuelStation(
        id: json['station_id'] as String? ?? 'station_1',
        name: json['station_name'] as String? ?? 'Fuel Station',
        brand: json['brand'] as String? ?? 'Indian Oil',
        rating: 4.5,
        ratingCount: 100,
        distanceKm: 2.0,
        etaMinutes: 15,
        pricePerLitre: (json['price_per_litre'] as num?)?.toDouble() ?? 102.5,
        availability: FuelAvailability.available,
        isOpen: true,
        address: json['station_address'] as String? ?? '',
      );
    }

    return FuelOrder(
      id: json['id'] as String? ?? '',
      fuelType: fuelType,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      deliveryLocation: location,
      station: station,
      vehicle: vehicle,
      priceEstimate: priceEstimate,
      status: status,
      invoice: invoice,
      paymentMethod: json['payment_method'] as String? ?? 'UPI',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
