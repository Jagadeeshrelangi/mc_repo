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
}
