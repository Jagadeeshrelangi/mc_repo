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

  bool get isSelectable => isOpen && availability != FuelAvailability.outOfStock;
}
