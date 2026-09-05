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
    );
  }

  factory ProfileVehicle.fromJson(Map<String, dynamic> json) {
    VehicleFuel fuel = VehicleFuel.petrol;
    final rawFuel = json['fuel_type']?.toString().toLowerCase();
    if (rawFuel == 'diesel') {
      fuel = VehicleFuel.diesel;
    } else if (rawFuel == 'electric') {
      fuel = VehicleFuel.electric;
    } else if (rawFuel == 'cng') {
      fuel = VehicleFuel.cng;
    }

    return ProfileVehicle(
      id: json['id']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      registration: json['registration']?.toString() ?? '',
      fuelType: fuel,
      insuranceExpiry: json['insurance_expiry'] != null
          ? DateTime.tryParse(json['insurance_expiry'].toString())
          : null,
      pucExpiry: json['puc_expiry'] != null
          ? DateTime.tryParse(json['puc_expiry'].toString())
          : null,
      serviceDueKm: json['service_due_km'] as int?,
      serviceDueDate: json['service_due_date'] != null
          ? DateTime.tryParse(json['service_due_date'].toString())
          : null,
      isDefault: json['is_default'] == true,
      healthScore: json['health_score'] as int? ?? 80,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'brand': brand,
      'model': model,
      'registration': registration,
      'fuel_type': fuelType.name,
      if (insuranceExpiry != null)
        'insurance_expiry': insuranceExpiry!.toIso8601String().split('T').first,
      if (pucExpiry != null)
        'puc_expiry': pucExpiry!.toIso8601String().split('T').first,
      if (serviceDueKm != null) 'service_due_km': serviceDueKm,
      if (serviceDueDate != null)
        'service_due_date': serviceDueDate!.toIso8601String().split('T').first,
      'is_default': isDefault,
      'health_score': healthScore,
    };
  }

  Map<String, dynamic> toUpdateJson() => toCreateJson();
}
