import 'package:flutter/material.dart';

/// Booking lifecycle states for the mock tracking flow.
///
/// Sprint 1.6: all states are driven through the repository/provider so the
/// same state machine can be wired to the real backend in Sprint 2.
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
  });

  Booking copyWith({BookingStatus? status}) {
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
    );
  }
}
