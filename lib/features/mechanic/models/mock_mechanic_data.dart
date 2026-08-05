import 'package:flutter/material.dart';
import 'mechanic_models.dart';

const List<MechanicCategory> mechanicCategories = [
  MechanicCategory(name: 'General Service', icon: Icons.build_rounded, color: Color(0xFFF15A22), bgColor: Color(0xFFFFF3ED), description: 'Regular maintenance & checkup'),
  MechanicCategory(name: 'Breakdown', icon: Icons.warning_amber_rounded, color: Color(0xFFEF4444), bgColor: Color(0xFFFEE2E2), description: 'Emergency breakdown help'),
  MechanicCategory(name: 'Battery', icon: Icons.battery_charging_full_rounded, color: Color(0xFFF59E0B), bgColor: Color(0xFFFEF3C7), description: 'Battery jumpstart & replacement'),
  MechanicCategory(name: 'Flat Tyre', icon: Icons.tire_repair_rounded, color: Color(0xFF3B82F6), bgColor: Color(0xFFEEF2FF), description: 'Puncture repair & tyre change'),
  MechanicCategory(name: 'Engine', icon: Icons.precision_manufacturing_rounded, color: Color(0xFF8B5CF6), bgColor: Color(0xFFF3EEFF), description: 'Engine diagnostics & repair'),
  MechanicCategory(name: 'Brake', icon: Icons.stop_circle_rounded, color: Color(0xFF10B981), bgColor: Color(0xFFD1FAE5), description: 'Brake pad replacement & service'),
  MechanicCategory(name: 'Electrical', icon: Icons.bolt_rounded, color: Color(0xFFEC4899), bgColor: Color(0xFFFDF2F8), description: 'Wiring & electrical fixes'),
  MechanicCategory(name: 'Towing', icon: Icons.local_shipping_rounded, color: Color(0xFF6B7280), bgColor: Color(0xFFF3F4F6), description: 'Vehicle towing service'),
];

final List<MechanicService> generalServices = [
  MechanicService(id: 'svc_1', name: 'General Service', icon: Icons.build_rounded, price: 499, estimatedMinutes: 60, description: 'Oil change, filter check, general inspection'),
  MechanicService(id: 'svc_2', name: 'Battery Service', icon: Icons.battery_charging_full_rounded, price: 299, estimatedMinutes: 30, description: 'Battery health check, jumpstart, replacement'),
  MechanicService(id: 'svc_3', name: 'Flat Tyre Repair', icon: Icons.tire_repair_rounded, price: 199, estimatedMinutes: 25, description: 'Puncture repair, tyre inflation, spare change'),
  MechanicService(id: 'svc_4', name: 'Engine Diagnostics', icon: Icons.precision_manufacturing_rounded, price: 699, estimatedMinutes: 90, description: 'Full engine scan, fault code reading'),
  MechanicService(id: 'svc_5', name: 'Brake Service', icon: Icons.stop_circle_rounded, price: 399, estimatedMinutes: 45, description: 'Brake pad inspection, replacement, fluid top-up'),
  MechanicService(id: 'svc_6', name: 'Electrical Repair', icon: Icons.bolt_rounded, price: 349, estimatedMinutes: 40, description: 'Wiring, lights, horn, switch repairs'),
  MechanicService(id: 'svc_7', name: 'Clutch Service', icon: Icons.settings_rounded, price: 549, estimatedMinutes: 75, description: 'Clutch cable adjustment, plate replacement'),
  MechanicService(id: 'svc_8', name: 'Oil Change', icon: Icons.oil_barrel_rounded, price: 249, estimatedMinutes: 20, description: 'Engine oil drain & refill'),
];

final List<MechanicInfo> mockMechanics = [
  MechanicInfo(
    id: 'm1',
    name: 'Rajesh Auto Garage',
    rating: 4.8,
    reviewCount: 126,
    experienceYears: 12,
    distanceKm: 1.2,
    etaMinutes: 8,
    isAvailable: true,
    priceStarting: 199,
    phone: '+91 98765 43210',
    skills: ['Engine', 'Brake', 'Electrical', 'Battery'],
    languages: ['English', 'Hindi', 'Telugu'],
    about: 'Rajesh Auto Garage has been serving vehicle owners for over 12 years. Specializing in two-wheeler and three-wheeler repairs, we provide reliable roadside assistance with genuine spare parts.',
    services: generalServices,
    workingHours: {'Mon-Fri': '8:00 AM - 8:00 PM', 'Sat': '9:00 AM - 6:00 PM', 'Sun': '10:00 AM - 4:00 PM'},
    isVerified: true,
  ),
  MechanicInfo(
    id: 'm2',
    name: 'Sai Mechanical Works',
    rating: 4.6,
    reviewCount: 89,
    experienceYears: 8,
    distanceKm: 0.8,
    etaMinutes: 5,
    isAvailable: true,
    priceStarting: 149,
    phone: '+91 98765 43211',
    skills: ['Battery', 'Flat Tyre', 'General Service', 'Oil Change'],
    languages: ['English', 'Hindi', 'Tamil'],
    about: 'Sai Mechanical Works offers quick and affordable roadside assistance. Our team is trained to handle most common vehicle issues on the spot.',
    services: generalServices.take(4).toList(),
    workingHours: {'Mon-Sat': '7:00 AM - 9:00 PM', 'Sun': '9:00 AM - 5:00 PM'},
    isVerified: true,
  ),
  MechanicInfo(
    id: 'm3',
    name: 'QuickFix Garage',
    rating: 4.3,
    reviewCount: 54,
    experienceYears: 5,
    distanceKm: 2.5,
    etaMinutes: 12,
    isAvailable: true,
    priceStarting: 179,
    phone: '+91 98765 43212',
    skills: ['Engine', 'Electrical', 'General Service'],
    languages: ['English', 'Hindi'],
    about: 'QuickFix Garage provides fast and efficient repair services. Our modern diagnostic tools help identify issues quickly and accurately.',
    services: [generalServices[0], generalServices[3], generalServices[5]],
    workingHours: {'Mon-Sat': '8:00 AM - 7:00 PM', 'Sun': 'Closed'},
    isVerified: false,
  ),
  MechanicInfo(
    id: 'm4',
    name: 'Sharma Auto Care',
    rating: 4.9,
    reviewCount: 203,
    experienceYears: 15,
    distanceKm: 3.8,
    etaMinutes: 18,
    isAvailable: false,
    priceStarting: 249,
    phone: '+91 98765 43213',
    skills: ['Engine', 'Brake', 'Clutch', 'Electrical', 'Towing'],
    languages: ['English', 'Hindi', 'Punjabi'],
    about: 'Sharma Auto Care is a premium two-wheeler service center with 15 years of experience. We specialize in complex repairs and use only OEM-grade spare parts.',
    services: generalServices,
    workingHours: {'Mon-Fri': '9:00 AM - 7:00 PM', 'Sat': '9:00 AM - 5:00 PM', 'Sun': 'Closed'},
    isVerified: true,
  ),
];

final List<MechanicInfo> featuredMechanics = [
  mockMechanics[0],
  mockMechanics[3],
  mockMechanics[1],
];

final Map<String, List<MechanicReview>> mechanicReviews = {
  'm1': const [
    MechanicReview(id: 'r1', reviewerName: 'Ravi Kumar', rating: 5, comment: 'Excellent service! Fixed my bike\'s engine issue within an hour.', date: '2 days ago', vehicle: 'Honda Activa 6G'),
    MechanicReview(id: 'r2', reviewerName: 'Priya Sharma', rating: 5, comment: 'Very professional and punctual. Highly recommended.', date: '1 week ago', vehicle: 'TVS Jupiter'),
    MechanicReview(id: 'r3', reviewerName: 'Anil Reddy', rating: 4, comment: 'Good work, reasonable prices. The mechanic was friendly.', date: '2 weeks ago', vehicle: 'Hero Splendor'),
  ],
  'm2': const [
    MechanicReview(id: 'r4', reviewerName: 'Suresh Patil', rating: 5, comment: 'Quick battery jumpstart at midnight. Lifesaver!', date: '3 days ago', vehicle: 'Maruti Alto'),
    MechanicReview(id: 'r5', reviewerName: 'Kavita Nair', rating: 4, comment: 'Affordable and quick tyre repair on the spot.', date: '1 week ago', vehicle: 'Yamaha FZ'),
  ],
  'm3': const [
    MechanicReview(id: 'r6', reviewerName: 'Mohit Verma', rating: 4, comment: 'Diagnosed the electrical issue fast. Could improve cleanliness.', date: '5 days ago', vehicle: 'Honda City'),
  ],
  'm4': const [
    MechanicReview(id: 'r7', reviewerName: 'Deepak Jain', rating: 5, comment: 'Best mechanic in town. Genuine parts and transparent billing.', date: '1 day ago', vehicle: 'Royal Enfield Classic 350'),
    MechanicReview(id: 'r8', reviewerName: 'Sunita Rao', rating: 5, comment: 'Clutch replacement done perfectly. Car feels brand new.', date: '4 days ago', vehicle: 'Hyundai i20'),
  ],
};
