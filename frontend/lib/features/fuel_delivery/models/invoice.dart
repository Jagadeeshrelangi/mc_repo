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

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceId: json['invoice_id'] as String? ?? json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      fuelType: json['fuel_type'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      pricePerLitre: (json['price_per_litre'] as num?)?.toDouble() ?? 0.0,
      fuelCost: (json['fuel_cost'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (json['delivery_charge'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0.0,
      taxes: (json['taxes'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      partnerName: json['partner_name'] as String? ?? '',
      vehicleNumber: json['vehicle_number'] as String? ?? '',
    );
  }
}
