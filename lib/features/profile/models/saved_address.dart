import 'package:flutter/material.dart';

/// Predefined address labels shown in the address picker.
enum AddressLabel {
  home,
  office,
  other;

  String get label => switch (this) {
        AddressLabel.home => 'Home',
        AddressLabel.office => 'Office',
        AddressLabel.other => 'Other',
      };

  IconData get icon => switch (this) {
        AddressLabel.home => Icons.home_rounded,
        AddressLabel.office => Icons.business_rounded,
        AddressLabel.other => Icons.place_rounded,
      };
}

/// A delivery / pickup address saved to the account.
class SavedAddress {
  final String id;
  final AddressLabel label;
  final String address;
  final double latitude;
  final double longitude;
  final bool isDefault;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });

  SavedAddress copyWith({
    String? id,
    AddressLabel? label,
    String? address,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
