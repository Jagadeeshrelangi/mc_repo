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

  factory PriceEstimate.fromJson(Map<String, dynamic> json) {
    return PriceEstimate(
      fuelCost: (json['fuel_cost'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (json['delivery_charge'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0.0,
      taxes: (json['taxes'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      etaMinutes: json['eta_minutes'] as int? ?? 15,
    );
  }
}
