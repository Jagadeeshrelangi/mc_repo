import 'package:flutter/material.dart';

/// How urgent a diagnosis is. Drives badge color, wording and the
/// "should I drive" guidance.
enum SeverityLevel {
  low,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case SeverityLevel.low:
        return 'Low';
      case SeverityLevel.medium:
        return 'Medium';
      case SeverityLevel.high:
        return 'High';
      case SeverityLevel.critical:
        return 'Critical';
    }
  }

  String get driveAdvice {
    switch (this) {
      case SeverityLevel.low:
        return 'Safe to drive. Keep a routine check on the part.';
      case SeverityLevel.medium:
        return 'Drive with care. Schedule service within 100 km.';
      case SeverityLevel.high:
        return 'Avoid long trips. Get it checked as soon as possible.';
      case SeverityLevel.critical:
        return 'Do not drive. Stop safely and call for assistance.';
    }
  }

  IconData get icon {
    switch (this) {
      case SeverityLevel.low:
        return Icons.check_circle_rounded;
      case SeverityLevel.medium:
        return Icons.info_rounded;
      case SeverityLevel.high:
        return Icons.warning_amber_rounded;
      case SeverityLevel.critical:
        return Icons.dangerous_rounded;
    }
  }
}

/// A structured diagnosis produced by the mock AI diagnostic engine.
class Diagnosis {
  final String id;
  final String vehicleName;
  final String vehicleType;
  final String problem;
  final List<String> symptoms;
  final List<String> possibleCauses;
  final SeverityLevel severity;
  final double estimatedCost;
  final String recommendedAction;
  final bool shouldDrive;
  final String recommendedService;
  final int confidence;
  final DateTime timestamp;

  const Diagnosis({
    required this.id,
    required this.vehicleName,
    required this.vehicleType,
    required this.problem,
    required this.symptoms,
    required this.possibleCauses,
    required this.severity,
    required this.estimatedCost,
    required this.recommendedAction,
    required this.shouldDrive,
    required this.recommendedService,
    required this.confidence,
    required this.timestamp,
  });
}
