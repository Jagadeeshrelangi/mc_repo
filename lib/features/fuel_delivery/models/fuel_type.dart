enum FuelType {
  petrol(name: 'Petrol', icon: '⛽', pricePerLitre: 98.20),
  diesel(name: 'Diesel', icon: '🛢️', pricePerLitre: 89.50);

  final String name;
  final String icon;
  final double pricePerLitre;

  const FuelType({
    required this.name,
    required this.icon,
    required this.pricePerLitre,
  });
}
