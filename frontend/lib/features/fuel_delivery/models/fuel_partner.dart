class FuelPartner {
  final String id;
  final String name;
  final String phone;
  final double rating;
  final int ratingCount;
  final double distance;
  final int etaMinutes;
  final bool isAvailable;
  final String vehicleNumber;
  final String vehicleModel;

  const FuelPartner({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    required this.ratingCount,
    required this.distance,
    required this.etaMinutes,
    this.isAvailable = true,
    required this.vehicleNumber,
    required this.vehicleModel,
  });
}
