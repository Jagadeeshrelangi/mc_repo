import 'fuel_type.dart';

class Vehicle {
  final String id;
  final String name;
  final String number;
  final FuelType fuelType;
  final String image;

  const Vehicle({
    required this.id,
    required this.name,
    required this.number,
    required this.fuelType,
    this.image = '',
  });
}
