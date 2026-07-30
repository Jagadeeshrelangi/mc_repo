import '../models/models.dart';
import '../constants/fuel_constants.dart';

class FuelService {
  PriceEstimate calculatePrice(FuelType fuelType, double quantity) {
    final validatedQuantity = quantity.clamp(FuelConstants.minLitres, FuelConstants.maxLitres);
    final fuelCost = fuelType.pricePerLitre * validatedQuantity;
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
      etaMinutes: 15,
    );
  }

  bool isValidQuantity(double quantity) {
    return quantity >= FuelConstants.minLitres && quantity <= FuelConstants.maxLitres;
  }
}
