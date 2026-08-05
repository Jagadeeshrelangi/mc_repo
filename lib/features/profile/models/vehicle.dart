import 'package:flutter/material.dart';

/// Fuel used by a registered vehicle.
enum VehicleFuel {
  petrol,
  diesel,
  electric,
  cng;

  String get label => switch (this) {
        VehicleFuel.petrol => 'Petrol',
        VehicleFuel.diesel => 'Diesel',
        VehicleFuel.electric => 'Electric',
        VehicleFuel.cng => 'CNG',
      };

  IconData get icon => switch (this) {
        VehicleFuel.petrol => Icons.local_gas_station_rounded,
        VehicleFuel.diesel => Icons.local_gas_station_rounded,
        VehicleFuel.electric => Icons.electric_bolt_rounded,
        VehicleFuel.cng => Icons.local_gas_station_rounded,
      };
}

/// A vehicle registered under the user's account.
class ProfileVehicle {
  final String id;
  final String brand;
  final String model;
  final String registration;
  final VehicleFuel fuelType;
  final DateTime? insuranceExpiry;
  final DateTime? pucExpiry;
  final int? serviceDueKm;
  final DateTime? serviceDueDate;
  final String? imageUrl;
  final bool isDefault;
  final int healthScore;

  const ProfileVehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.registration,
    required this.fuelType,
    this.insuranceExpiry,
    this.pucExpiry,
    this.serviceDueKm,
    this.serviceDueDate,
    this.imageUrl,
    this.isDefault = false,
    this.healthScore = 80,
  });

  String get name => '$brand $model';

  ProfileVehicle copyWith({
    String? id,
    String? brand,
    String? model,
    String? registration,
    VehicleFuel? fuelType,
    DateTime? insuranceExpiry,
    DateTime? pucExpiry,
    int? serviceDueKm,
    DateTime? serviceDueDate,
    String? imageUrl,
    bool? isDefault,
    int? healthScore,
    bool clearInsuranceExpiry = false,
    bool clearPucExpiry = false,
    bool clearServiceDueDate = false,
  }) {
    return ProfileVehicle(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      registration: registration ?? this.registration,
      fuelType: fuelType ?? this.fuelType,
      insuranceExpiry:
          clearInsuranceExpiry ? null : (insuranceExpiry ?? this.insuranceExpiry),
      pucExpiry: clearPucExpiry ? null : (pucExpiry ?? this.pucExpiry),
      serviceDueKm: serviceDueKm ?? this.serviceDueKm,
      serviceDueDate:
          clearServiceDueDate ? null : (serviceDueDate ?? this.serviceDueDate),
      imageUrl: imageUrl ?? this.imageUrl,
      isDefault: isDefault ?? this.isDefault,
      healthScore: healthScore ?? this.healthScore,
    );
  }
}
