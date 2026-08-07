import 'package:flutter/material.dart';

enum VehicleType {
  bike('Bike', Icons.two_wheeler_rounded),
  car('Car', Icons.directions_car_rounded),
  suv('SUV', Icons.airport_shuttle_rounded),
  truck('Truck', Icons.local_shipping_rounded),
  other('Other', Icons.help_outline_rounded);

  final String label;
  final IconData icon;
  const VehicleType(this.label, this.icon);
}

class FuelVehicle {
  final String id;
  final VehicleType type;
  final String name;
  final String number;

  const FuelVehicle({
    required this.id,
    required this.type,
    required this.name,
    required this.number,
  });

  /// Short label for order summaries (e.g. "Car • KA-01-AB-1234").
  String get summary => '$name • $number';
}
