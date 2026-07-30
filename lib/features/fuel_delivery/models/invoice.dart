class Invoice {
  final String invoiceId;
  final String orderId;
  final DateTime createdAt;
  final String fuelType;
  final double quantity;
  final double pricePerLitre;
  final double fuelCost;
  final double deliveryCharge;
  final double platformFee;
  final double taxes;
  final double grandTotal;
  final String partnerName;
  final String vehicleNumber;

  const Invoice({
    required this.invoiceId,
    required this.orderId,
    required this.createdAt,
    required this.fuelType,
    required this.quantity,
    required this.pricePerLitre,
    required this.fuelCost,
    required this.deliveryCharge,
    required this.platformFee,
    required this.taxes,
    required this.grandTotal,
    required this.partnerName,
    required this.vehicleNumber,
  });
}
