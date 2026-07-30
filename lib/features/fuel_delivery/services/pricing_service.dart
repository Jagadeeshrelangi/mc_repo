import '../models/fuel_type.dart';
import '../models/price_estimate.dart';

class PricingService {
  PriceEstimate calculate({required FuelType fuelType, required double quantity, required double deliveryDistance}) {
    final fuelCost = fuelType.pricePerLitre * quantity;
    final deliveryCharge = 10.0 + (deliveryDistance * 5.0);
    final platformFee = 5.0;
    final taxes = (fuelCost + deliveryCharge + platformFee) * 0.02;
    final grandTotal = fuelCost + deliveryCharge + platformFee + taxes;
    final etaMinutes = 10 + (deliveryDistance / 0.5).round();

    return PriceEstimate(
      fuelCost: fuelCost,
      deliveryCharge: deliveryCharge,
      platformFee: platformFee,
      taxes: taxes,
      grandTotal: grandTotal,
      etaMinutes: etaMinutes,
    );
  }
}
