import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mecha_connect/services/api_client.dart';
import '../models/models.dart';
import '../repositories/ai_repository.dart';

/// Parses diagnostic payloads into typed [Diagnosis] models.
///
/// Supports both FastAPI backend response shapes (`DiagnosisResponse`)
/// and in-memory mock diagnostic payloads.
class DiagnosisService {
  final AiRepository _repository;
  final ApiClient _apiClient;
  final bool enableFallback;

  DiagnosisService({
    AiRepository? repository,
    ApiClient? apiClient,
    this.enableFallback = true,
  })  : _repository = repository ?? AiRepository(),
        _apiClient = apiClient ?? ApiClient();

  /// Runs diagnosis against the real FastAPI backend when available,
  /// falling back gracefully to the mock engine in offline/test modes.
  Future<Diagnosis> diagnose({
    required String vehicleName,
    required String vehicleType,
    required String problem,
    required List<String> symptoms,
  }) async {
    try {
      final payload = {
        'mileage': 50000,
        'vehicle_type': vehicleType,
        'symptoms': symptoms,
        'brand': vehicleName.split(' ').first,
        'model': vehicleName.split(' ').skip(1).join(' '),
      };

      final res = await _apiClient.post(
        '/api/v1/diagnosis/diagnose',
        body: payload,
        requiresAuth: true,
      );

      if (res is Map<String, dynamic>) {
        return parseDiagnosis(
          res,
          vehicleName: vehicleName,
          inputSymptoms: symptoms,
          isOfflineFallback: false,
        );
      }
    } catch (e) {
      if (!enableFallback) rethrow;
      debugPrint('Backend diagnosis call fell back to local engine: $e');
    }

    final raw = await _repository.diagnoseVehicle(
      vehicleType: vehicleType,
      problem: problem,
      symptoms: symptoms,
    );
    return parseDiagnosis(raw, vehicleName: vehicleName, isOfflineFallback: true);
  }

  /// Parses a diagnosis map into [Diagnosis].
  /// Handles both backend `DiagnosisResponse` and mock diagnostic payload formats.
  Diagnosis parseDiagnosis(
    Map<String, dynamic> raw, {
    required String vehicleName,
    List<String>? inputSymptoms,
    bool isOfflineFallback = false,
  }) {
    final id = raw['id'] as String? ?? 'diag-unknown';
    final vehicleType = raw['vehicle_type'] as String? ?? vehicleName;

    // Support backend 'predicted_fault' or mock 'problem'
    final problem = raw['predicted_fault'] as String? ??
        raw['problem'] as String? ??
        'General issue';

    final symptoms = (raw['symptoms'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        inputSymptoms ??
        const [];

    final rawCauses = (raw['possible_causes'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();

    // If causes are missing and it is not a recognized backend prediction, throw FormatException for invalid test inputs like {'problem': 'x'}
    if ((rawCauses == null || rawCauses.isEmpty) &&
        raw['predicted_fault'] == null &&
        raw['problem'] != null) {
      throw const FormatException('Diagnosis payload has no possible causes');
    }

    final causes = (rawCauses != null && rawCauses.isNotEmpty)
        ? rawCauses
        : [raw['predicted_fault'] as String? ?? problem];

    final severity = _parseSeverity(raw['severity'] as String?);
    final estimatedCost = (raw['estimated_cost'] as num?)?.toDouble() ?? 0;

    // Support backend 'safety_advice' or mock 'recommended_action'
    final recommendedAction = raw['safety_advice'] as String? ??
        raw['recommended_action'] as String? ??
        'Get the vehicle inspected.';

    final shouldDrive = raw['should_drive'] as bool? ??
        (raw['safety_advice'] != null
            ? !raw['safety_advice'].toString().toUpperCase().contains('STOP')
            : true);

    // Support backend 'repair_time' or mock 'recommended_service'
    final recommendedService = raw['recommended_service'] as String? ??
        raw['repair_time'] as String? ??
        'General Inspection';

    // Scale confidence: if 0.0-1.0 float, scale to 0-100; if already integer, keep
    num? rawConf = raw['confidence'] as num?;
    int confidence = 0;
    if (rawConf != null) {
      if (rawConf <= 1.0 && rawConf > 0.0) {
        confidence = (rawConf * 100).round();
      } else {
        confidence = rawConf.toInt();
      }
    }

    final timestamp = DateTime.tryParse(
            raw['timestamp'] as String? ?? raw['created_at'] as String? ?? '') ??
        DateTime.now();

    return Diagnosis(
      id: id,
      vehicleName: vehicleName,
      vehicleType: vehicleType,
      problem: problem,
      symptoms: symptoms,
      possibleCauses: causes,
      severity: severity,
      estimatedCost: estimatedCost,
      recommendedAction: recommendedAction,
      shouldDrive: shouldDrive,
      recommendedService: recommendedService,
      confidence: confidence,
      timestamp: timestamp,
      isOfflineFallback: isOfflineFallback,
    );
  }

  SeverityLevel _parseSeverity(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return SeverityLevel.low;
      case 'medium':
        return SeverityLevel.medium;
      case 'high':
        return SeverityLevel.high;
      case 'critical':
        return SeverityLevel.critical;
      default:
        return SeverityLevel.medium;
    }
  }
}
