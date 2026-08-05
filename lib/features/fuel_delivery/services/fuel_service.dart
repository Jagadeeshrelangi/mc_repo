import '../models/models.dart';
import '../constants/fuel_constants.dart';

class FuelService {
  /// Calculates the price estimate for the given fuel and quantity.
  ///
  /// [pricePerLitre] defaults to the fuel type's base rate; pass a station's
  /// rate to reflect that pump's pricing.
  PriceEstimate calculatePrice(
    FuelType fuelType,
    double quantity, {
    double? pricePerLitre,
    int? etaMinutes,
  }) {
    final validatedQuantity = quantity.clamp(FuelConstants.minLitres, FuelConstants.maxLitres);
    final rate = pricePerLitre ?? fuelType.pricePerLitre;
    final fuelCost = rate * validatedQuantity;
    final deliveryCharge = FuelConstants.deliveryCharge;
    final platformFee = FuelConstants.platformFee;
    final taxes = (fuelCost + deliveryCharge + platformFee) * FuelConstants.taxRate;
    final grandTotal = fuelCost + deliveryCharge + platformFee + taxes;

    return PriceEstimate(
      fuelCost: fuelCost,
      deliveryCharge: deliveryCharge,
      platformFee: platformFee,
      taxes: taxes,
      grandTotal: grandTotal,
      etaMinutes: etaMinutes ?? 15,
    );
  }

  bool isValidQuantity(double quantity) {
    return quantity >= FuelConstants.minLitres && quantity <= FuelConstants.maxLitres;
  }
}
