import 'package:flutter/material.dart';

class UserProfile {
  final String name;
  final String greeting;
  final String avatarUrl;

  const UserProfile({
    this.name = 'Jagadeesh',
    this.greeting = 'Good Afternoon',
    this.avatarUrl = '',
  });
}

class LocationInfo {
  final String area;
  final String city;
  final String fullAddress;

  const LocationInfo({
    this.area = 'Surampalem',
    this.city = 'Andhra Pradesh',
    this.fullAddress = 'Surampalem, Andhra Pradesh',
  });
}

class VehicleInfo {
  final String name;
  final int healthPercent;
  final int fuelPercent;
  final String battery;
  final String lastService;
  final String insurance;
  final String imageUrl;

  const VehicleInfo({
    this.name = 'Honda Activa 6G',
    this.healthPercent = 92,
    this.fuelPercent = 65,
    this.battery = 'Healthy',
    this.lastService = '15 days ago',
    this.insurance = 'Valid',
    this.imageUrl = '',
  });
}

class QuickService {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const QuickService({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });
}

class NearbyService {
  final String name;
  final String distance;
  final double rating;
  final bool isOpen;
  final String category;
  final String imageUrl;

  const NearbyService({
    required this.name,
    required this.distance,
    this.rating = 4.0,
    this.isOpen = true,
    required this.category,
    this.imageUrl = '',
  });
}

class MarketplaceItem {
  final String name;
  final String price;
  final IconData icon;
  final String imageUrl;

  const MarketplaceItem({
    required this.name,
    required this.price,
    required this.icon,
    this.imageUrl = '',
  });
}

class ActivityItem {
  final String title;
  final String status;
  final IconData icon;
  final Color statusColor;
  final bool isCompleted;

  const ActivityItem({
    required this.title,
    required this.status,
    required this.icon,
    required this.statusColor,
    this.isCompleted = true,
  });
}

class OfferInfo {
  final String title;
  final String discount;
  final String description;
  final String code;
  final Color gradientStart;
  final Color gradientEnd;

  const OfferInfo({
    required this.title,
    required this.discount,
    required this.description,
    required this.code,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

const UserProfile mockUser = UserProfile();
const LocationInfo mockLocation = LocationInfo();
const VehicleInfo mockVehicle = VehicleInfo();

const List<QuickService> mockQuickServices = [
  QuickService(
    icon: Icons.build_rounded,
    label: 'Mechanic',
    color: Color(0xFFF15A22),
    bgColor: Color(0xFFFFF3ED),
  ),
  QuickService(
    icon: Icons.local_gas_station_rounded,
    label: 'Fuel',
    color: Color(0xFF3B82F6),
    bgColor: Color(0xFFEEF2FF),
  ),
  QuickService(
    icon: Icons.biotech_rounded,
    label: 'AI Diagnosis',
    color: Color(0xFF8B5CF6),
    bgColor: Color(0xFFF3EEFF),
  ),
  QuickService(
    icon: Icons.shopping_bag_rounded,
    label: 'Parts',
    color: Color(0xFF10B981),
    bgColor: Color(0xFFD1FAE5),
  ),
  QuickService(
    icon: Icons.battery_charging_full_rounded,
    label: 'Battery',
    color: Color(0xFFF59E0B),
    bgColor: Color(0xFFFEF3C7),
  ),
  QuickService(
    icon: Icons.local_shipping_rounded,
    label: 'Towing',
    color: Color(0xFFEF4444),
    bgColor: Color(0xFFFEE2E2),
  ),
];

const List<NearbyService> mockNearbyServices = [
  NearbyService(
    name: 'Ram\'s Garage',
    distance: '2.3 km',
    rating: 4.5,
    category: 'Mechanic',
  ),
  NearbyService(
    name: 'Indian Oil Pump',
    distance: '1.5 km',
    rating: 4.2,
    category: 'Fuel Station',
  ),
  NearbyService(
    name: 'Exide Battery Point',
    distance: '3.1 km',
    rating: 4.0,
    category: 'Battery Shop',
  ),
  NearbyService(
    name: 'Sai Tyre Center',
    distance: '0.8 km',
    rating: 4.3,
    category: 'Tyre Shop',
  ),
  NearbyService(
    name: 'AutoParts Hub',
    distance: '4.2 km',
    rating: 4.6,
    category: 'Spare Parts',
  ),
];

const List<MarketplaceItem> mockMarketplaceItems = [
  MarketplaceItem(name: 'Engine Oil', price: '₹899', icon: Icons.oil_barrel_rounded),
  MarketplaceItem(name: 'Brake Pads', price: '₹699', icon: Icons.disc_full_rounded),
  MarketplaceItem(name: 'Helmet', price: '₹1,499', icon: Icons.safety_check_rounded),
  MarketplaceItem(name: 'Battery', price: '₹3,499', icon: Icons.battery_charging_full_rounded),
];

const List<ActivityItem> mockActivity = [
  ActivityItem(title: 'Engine Oil Changed', status: 'Completed', icon: Icons.oil_barrel_rounded, statusColor: Color(0xFF10B981)),
  ActivityItem(title: 'Fuel Delivery', status: 'Delivered', icon: Icons.local_gas_station_rounded, statusColor: Color(0xFF10B981)),
  ActivityItem(title: 'Battery Check', status: 'Completed', icon: Icons.battery_std_rounded, statusColor: Color(0xFF10B981)),
  ActivityItem(title: 'Service Booking', status: 'Upcoming', icon: Icons.event_rounded, statusColor: Color(0xFFF59E0B)),
];

const OfferInfo mockOffer = OfferInfo(
  title: 'First Service',
  discount: '20% OFF',
  description: 'On your first vehicle service booking',
  code: 'MECHA20',
  gradientStart: Color(0xFFF15A22),
  gradientEnd: Color(0xFFD44A15),
);
