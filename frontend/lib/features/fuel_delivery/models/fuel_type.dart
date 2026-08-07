import 'package:flutter/material.dart';

enum FuelType {
  petrol(
    name: 'Petrol',
    icon: Icons.local_gas_station_rounded,
    pricePerLitre: 98.20,
  ),
  diesel(
    name: 'Diesel',
    icon: Icons.oil_barrel_rounded,
    pricePerLitre: 89.50,
  ),
  premiumPetrol(
    name: 'Premium Petrol',
    icon: Icons.bolt_rounded,
    pricePerLitre: 108.50,
  ),
  electric(
    name: 'Electric Charging',
    icon: Icons.electric_bolt_rounded,
    pricePerLitre: 0,
    comingSoon: true,
  ),
  cng(
    name: 'CNG',
    icon: Icons.local_fire_department_rounded,
    pricePerLitre: 0,
    comingSoon: true,
  );

  final String name;
  final IconData icon;
  final double pricePerLitre;
  final bool comingSoon;

  const FuelType({
    required this.name,
    required this.icon,
    required this.pricePerLitre,
    this.comingSoon = false,
  });

  /// Orderable fuels only (excludes coming-soon options).
  static List<FuelType> get orderable =>
      FuelType.values.where((t) => !t.comingSoon).toList();
}
