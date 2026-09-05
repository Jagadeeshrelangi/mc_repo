enum FuelAvailability { available, low, outOfStock }

class FuelStation {
  final String id;
  final String name;
  final double rating;
  final int ratingCount;
  final double distanceKm;
  final int etaMinutes;
  final double pricePerLitre;
  final FuelAvailability availability;
  final bool isOpen;
  final String address;
  final String brand;

  const FuelStation({
    required this.id,
    required this.name,
    required this.rating,
    required this.ratingCount,
    required this.distanceKm,
    required this.etaMinutes,
    required this.pricePerLitre,
    required this.availability,
    required this.isOpen,
    required this.address,
    required this.brand,
  });

  factory FuelStation.fromJson(Map<String, dynamic> json) {
    FuelAvailability avail;
    final aStr = (json['availability'] as String? ?? 'available').toLowerCase();
    if (aStr == 'low') {
      avail = FuelAvailability.low;
    } else if (aStr == 'outofstock' || aStr == 'out_of_stock') {
      avail = FuelAvailability.outOfStock;
    } else {
      avail = FuelAvailability.available;
    }
    return FuelStation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      address: json['address'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.0,
      ratingCount: json['rating_count'] as int? ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 2.5,
      etaMinutes: json['eta_minutes'] as int? ?? 15,
      pricePerLitre: (json['price_per_litre'] as num?)?.toDouble() ?? 102.5,
      availability: avail,
      isOpen: json['is_open'] as bool? ?? true,
    );
  }

  bool get isSelectable => isOpen && availability != FuelAvailability.outOfStock;
}
