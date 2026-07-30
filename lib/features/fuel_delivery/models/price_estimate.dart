class PriceEstimate {
  final double fuelCost;
  final double deliveryCharge;
  final double platformFee;
  final double taxes;
  final double grandTotal;
  final int etaMinutes;

  const PriceEstimate({
    required this.fuelCost,
    required this.deliveryCharge,
    required this.platformFee,
    required this.taxes,
    required this.grandTotal,
    required this.etaMinutes,
  });
}
