import 'package:flutter/material.dart';
import 'review.dart';

/// Vehicle categories a product is compatible with.
enum VehicleType {
  bike,
  car,
  suv,
  truck;

  String get label {
    switch (this) {
      case VehicleType.bike:
        return 'Bike';
      case VehicleType.car:
        return 'Car';
      case VehicleType.suv:
        return 'SUV';
      case VehicleType.truck:
        return 'Truck';
    }
  }
}

extension VehicleTypeX on VehicleType {
  IconData get icon {
    switch (this) {
      case VehicleType.bike:
        return Icons.two_wheeler_rounded;
      case VehicleType.car:
        return Icons.directions_car_filled_rounded;
      case VehicleType.suv:
        return Icons.local_taxi_rounded;
      case VehicleType.truck:
        return Icons.local_shipping_rounded;
    }
  }
}

/// A part/accessory manufacturer. Kept as a first-class model so filters and
/// the category pages can render brands without string parsing.
class Brand {
  final String id;
  final String name;

  const Brand({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      other is Brand && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// A marketplace browse category. Icons are Material icons so the whole app
/// stays asset-light and works identically in light/dark mode.
class Category {
  final String id;
  final String name;
  final IconData icon;

  const Category({required this.id, required this.name, required this.icon});

  @override
  bool operator ==(Object other) =>
      other is Category && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// A single row in the product specifications table.
class ProductSpecification {
  final String label;
  final String value;

  const ProductSpecification({required this.label, required this.value});
}

/// A marketplace product. Prices are MRP-inclusive sale prices; [mrp] holds the
/// original price so discounts can be shown. Images are optional asset paths —
/// when null (or when an asset fails to load) the UI falls back to [icon].
class Product {
  final String id;
  final String name;
  final String brand;
  final String brandId;
  final String categoryId;
  final double price;
  final double mrp;
  final double rating;
  final int ratingCount;
  final int stock;
  final String? imageUrl;
  final IconData icon;
  final String description;
  final List<ProductSpecification> specifications;
  final List<VehicleType> vehicleTypes;
  final List<String> compatibility;
  final String warranty;
  final String deliveryEstimate;
  final int popularity;
  final int ageDays;
  final bool isFeatured;
  final bool isBestSeller;
  final bool isTrending;
  final bool isFlashDeal;
  final bool isRecommended;
  final List<Review> reviews;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.brandId,
    required this.categoryId,
    required this.price,
    required this.mrp,
    this.rating = 4.0,
    this.ratingCount = 0,
    this.stock = 25,
    this.imageUrl,
    this.icon = Icons.inventory_2_rounded,
    this.description = '',
    this.specifications = const [],
    this.vehicleTypes = const [VehicleType.bike, VehicleType.car],
    this.compatibility = const [],
    this.warranty = '6 months brand warranty',
    this.deliveryEstimate = 'Delivery in 3-5 days',
    this.popularity = 0,
    this.ageDays = 0,
    this.isFeatured = false,
    this.isBestSeller = false,
    this.isTrending = false,
    this.isFlashDeal = false,
    this.isRecommended = false,
    this.reviews = const [],
  });

  /// Discount against MRP, rounded to a whole percentage.
  double get discountPercent =>
      mrp <= 0 ? 0 : ((mrp - price) / mrp * 100).roundToDouble();

  bool get inStock => stock > 0;

  /// A second, related image used by the image carousel / review photos when
  /// present. Falls back to [imageUrl].
  String? get carouselImageUrl => imageUrl;
}
