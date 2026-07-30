import 'fuel_type.dart';
import 'delivery_location.dart';
import 'fuel_partner.dart';
import 'price_estimate.dart';
import 'order_status.dart';
import 'invoice.dart';

class FuelOrder {
  final String id;
  final FuelType fuelType;
  final double quantity;
  final DeliveryLocation deliveryLocation;
  final FuelPartner? partner;
  final PriceEstimate priceEstimate;
  final OrderStatus status;
  final Invoice? invoice;
  final DateTime createdAt;
  final String vehicleName;
  final String vehicleNumber;

  const FuelOrder({
    required this.id,
    required this.fuelType,
    required this.quantity,
    required this.deliveryLocation,
    this.partner,
    required this.priceEstimate,
    required this.status,
    this.invoice,
    required this.createdAt,
    required this.vehicleName,
    required this.vehicleNumber,
  });
}
