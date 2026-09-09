import 'package:flutter/material.dart';

/// Booking lifecycle states for the tracking flow.
///
/// Values match the backend `BookingStatus` enum 1:1:
/// requested → accepted → mechanicAssigned → enRoute → arrived → completed (+ cancelled)
enum BookingStatus {
  requested,
  accepted,
  mechanicAssigned,
  enRoute,
  arrived,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case BookingStatus.requested:
        return 'Requested';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.mechanicAssigned:
        return 'Mechanic Assigned';
      case BookingStatus.enRoute:
        return 'Mechanic En Route';
      case BookingStatus.arrived:
        return 'Arrived';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  IconData get icon {
    switch (this) {
      case BookingStatus.requested:
        return Icons.send_rounded;
      case BookingStatus.accepted:
        return Icons.thumb_up_alt_rounded;
      case BookingStatus.mechanicAssigned:
        return Icons.person_pin_rounded;
      case BookingStatus.enRoute:
        return Icons.near_me_rounded;
      case BookingStatus.arrived:
        return Icons.location_on_rounded;
      case BookingStatus.completed:
        return Icons.check_circle_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  static BookingStatus fromString(String? val) {
    if (val == null) return BookingStatus.requested;
    for (final s in BookingStatus.values) {
      if (s.name == val || s.name.toLowerCase() == val.toLowerCase()) {
        return s;
      }
    }
    return BookingStatus.requested;
  }

  String get toBackendValue => name;
}

class BookingEventModel {
  final String id;
  final String bookingId;
  final String status;
  final DateTime occurredAt;
  final Map<String, dynamic> payload;

  const BookingEventModel({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.occurredAt,
    this.payload = const {},
  });

  factory BookingEventModel.fromJson(Map<String, dynamic> json) {
    return BookingEventModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      occurredAt: DateTime.tryParse(json['occurred_at']?.toString() ?? '') ?? DateTime.now(),
      payload: json['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
    );
  }
}

class MechanicInfo {
  final String id;
  final String name;
  final String photoUrl;
  final double rating;
  final int reviewCount;
  final int experienceYears;
  final double distanceKm;
  final int etaMinutes;
  final bool isAvailable;
  final double priceStarting;
  final String phone;
  final List<String> skills;
  final List<String> languages;
  final String about;
  final List<MechanicService> services;
  final Map<String, String> workingHours;
  final bool isVerified;

  const MechanicInfo({
    required this.id,
    required this.name,
    this.photoUrl = '',
    required this.rating,
    this.reviewCount = 0,
    this.experienceYears = 0,
    this.distanceKm = 0,
    this.etaMinutes = 15,
    this.isAvailable = true,
    this.priceStarting = 0,
    this.phone = '',
    this.skills = const [],
    this.languages = const ['English', 'Hindi'],
    this.about = '',
    this.services = const [],
    this.workingHours = const {},
    this.isVerified = false,
  });

  factory MechanicInfo.fromJson(Map<String, dynamic> json) {
    final whMap = <String, String>{};
    if (json['working_hours'] is List) {
      for (final wh in json['working_hours']) {
        if (wh is Map<String, dynamic>) {
          final day = wh['day']?.toString() ?? '';
          final open = wh['open']?.toString() ?? '';
          final close = wh['close']?.toString() ?? '';
          whMap[day] = open.isNotEmpty && close.isNotEmpty ? '$open - $close' : '8:00 AM - 8:00 PM';
        }
      }
    } else if (json['workingHours'] is Map<String, dynamic>) {
      json['workingHours'].forEach((k, v) => whMap[k.toString()] = v.toString());
    }

    final sList = <MechanicService>[];
    if (json['services'] is List) {
      for (final s in json['services']) {
        if (s is Map<String, dynamic>) {
          sList.add(MechanicService.fromJson(s));
        }
      }
    }

    return MechanicInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Mechanic',
      photoUrl: json['photo_url']?.toString() ?? json['photoUrl']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? (json['reviewCount'] as num?)?.toInt() ?? 0,
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? (json['experienceYears'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? (json['distanceKm'] as num?)?.toDouble() ?? 1.5,
      etaMinutes: (json['eta_minutes'] as num?)?.toInt() ?? (json['etaMinutes'] as num?)?.toInt() ?? 15,
      isAvailable: json['is_available'] as bool? ?? json['isAvailable'] as bool? ?? true,
      priceStarting: (json['price_starting'] as num?)?.toDouble() ?? (json['priceStarting'] as num?)?.toDouble() ?? 199.0,
      phone: json['phone']?.toString() ?? '',
      skills: (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ?? const ['English', 'Hindi'],
      about: json['about']?.toString() ?? '',
      services: sList,
      workingHours: whMap,
      isVerified: json['is_verified'] as bool? ?? json['isVerified'] as bool? ?? true,
    );
  }

  MechanicInfo copyWith({bool? isAvailable}) {
    return MechanicInfo(
      id: id,
      name: name,
      photoUrl: photoUrl,
      rating: rating,
      reviewCount: reviewCount,
      experienceYears: experienceYears,
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
      isAvailable: isAvailable ?? this.isAvailable,
      priceStarting: priceStarting,
      phone: phone,
      skills: skills,
      languages: languages,
      about: about,
      services: services,
      workingHours: workingHours,
      isVerified: isVerified,
    );
  }
}

class MechanicService {
  final String id;
  final String name;
  final IconData icon;
  final double price;
  final int estimatedMinutes;
  final String description;

  const MechanicService({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    required this.estimatedMinutes,
    this.description = '',
  });

  factory MechanicService.fromJson(Map<String, dynamic> json) {
    return MechanicService(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: _mapServiceIcon(json['icon']?.toString()),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? (json['estimatedMinutes'] as num?)?.toInt() ?? 30,
      description: json['description']?.toString() ?? '',
    );
  }

  static IconData _mapServiceIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'build':
      case 'engine':
        return Icons.build_rounded;
      case 'tire':
      case 'tire_repair':
        return Icons.tire_repair_rounded;
      case 'battery':
      case 'battery_charging_full':
        return Icons.battery_charging_full_rounded;
      case 'oil':
      case 'oil_barrel':
        return Icons.oil_barrel_rounded;
      case 'car_repair':
        return Icons.car_repair_rounded;
      case 'electric_bolt':
        return Icons.electric_bolt_rounded;
      case 'ac_unit':
        return Icons.ac_unit_rounded;
      default:
        return Icons.build_rounded;
    }
  }
}

class MechanicCategory {
  final String name;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String description;

  const MechanicCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.description = '',
  });

  factory MechanicCategory.fromJson(Map<String, dynamic> json) {
    return MechanicCategory(
      name: json['name']?.toString() ?? '',
      icon: MechanicService._mapServiceIcon(json['icon']?.toString()),
      color: const Color(0xFF2563EB),
      bgColor: const Color(0xFFEFF6FF),
      description: json['description']?.toString() ?? '',
    );
  }
}

class MechanicReview {
  final String id;
  final String reviewerName;
  final double rating;
  final String comment;
  final String date;
  final String vehicle;

  const MechanicReview({
    required this.id,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.date,
    this.vehicle = '',
  });

  factory MechanicReview.fromJson(Map<String, dynamic> json) {
    return MechanicReview(
      id: json['id']?.toString() ?? '',
      reviewerName: json['reviewer_name']?.toString() ?? json['reviewerName']?.toString() ?? 'Verified Driver',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comment: json['comment']?.toString() ?? '',
      date: json['reviewed_at']?.toString() ?? json['date']?.toString() ?? 'Recently',
      vehicle: json['vehicle']?.toString() ?? '',
    );
  }
}

/// A user booking request captured by the vehicle form + service selection.
class BookingRequest {
  final String vehicleType;
  final String brand;
  final String model;
  final String fuelType;
  final String registration;
  final String problemDescription;
  final String address;
  final bool isEmergency;

  const BookingRequest({
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.fuelType,
    required this.registration,
    required this.problemDescription,
    required this.address,
    this.isEmergency = false,
  });

  String get vehicleSummary =>
      '$brand $model'.trim().isEmpty ? vehicleType : '$brand $model';
}

/// A confirmed/tracked booking.
class Booking {
  final String bookingId;
  final MechanicInfo mechanic;
  final MechanicService service;
  final String vehicle;
  final String address;
  final DateTime estimatedArrival;
  final double estimatedCost;
  final BookingStatus status;
  final DateTime bookingTime;
  final List<BookingEventModel> events;

  const Booking({
    required this.bookingId,
    required this.mechanic,
    required this.service,
    required this.vehicle,
    required this.address,
    required this.estimatedArrival,
    required this.estimatedCost,
    required this.status,
    required this.bookingTime,
    this.events = const [],
  });

  factory Booking.fromJson(
    Map<String, dynamic> json, {
    MechanicInfo? mechanic,
    MechanicService? service,
  }) {
    final mech = mechanic ??
        (json['mechanic'] is Map<String, dynamic>
            ? MechanicInfo.fromJson(json['mechanic'] as Map<String, dynamic>)
            : MechanicInfo(
                id: json['mechanic_id']?.toString() ?? 'm1',
                name: 'Verified Mechanic',
                rating: 4.8,
              ));

    final svc = service ??
        (json['service'] is Map<String, dynamic>
            ? MechanicService.fromJson(json['service'] as Map<String, dynamic>)
            : MechanicService(
                id: json['service_id']?.toString() ?? 'svc_general',
                name: 'General Service',
                icon: Icons.build_rounded,
                price: (json['estimated_cost'] as num?)?.toDouble() ?? 299.0,
                estimatedMinutes: 30,
              ));

    final eventsList = <BookingEventModel>[];
    if (json['events'] is List) {
      for (final e in json['events']) {
        if (e is Map<String, dynamic>) {
          eventsList.add(BookingEventModel.fromJson(e));
        }
      }
    }

    return Booking(
      bookingId: json['id']?.toString() ?? json['bookingId']?.toString() ?? 'MEC-${DateTime.now().millisecondsSinceEpoch}',
      mechanic: mech,
      service: svc,
      vehicle: json['vehicle_name']?.toString() ?? json['vehicle']?.toString() ?? 'Vehicle',
      address: json['address']?.toString() ?? '',
      estimatedArrival: DateTime.tryParse(json['scheduled_at']?.toString() ?? '') ??
          DateTime.now().add(Duration(minutes: mech.etaMinutes)),
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? svc.price,
      status: BookingStatus.fromString(json['status']?.toString()),
      bookingTime: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      events: eventsList,
    );
  }

  Booking copyWith({
    BookingStatus? status,
    List<BookingEventModel>? events,
  }) {
    return Booking(
      bookingId: bookingId,
      mechanic: mechanic,
      service: service,
      vehicle: vehicle,
      address: address,
      estimatedArrival: estimatedArrival,
      estimatedCost: estimatedCost,
      status: status ?? this.status,
      bookingTime: bookingTime,
      events: events ?? this.events,
    );
  }
}
