import '../models/models.dart';
import '../repositories/ai_repository.dart';

/// Parses the raw mock diagnostic payload into a typed [Diagnosis].
///
/// Keeps model mapping (string → [SeverityLevel], JSON → [Diagnosis]) out of
/// the screens and provider. In Sprint 2 the same parser handles the real
/// backend response shape.
class DiagnosisService {
  final AiRepository _repository;

  DiagnosisService({AiRepository? repository})
      : _repository = repository ?? AiRepository();

  /// Runs the guided diagnosis through the mock engine and returns a typed,
  /// validated [Diagnosis].
  Future<Diagnosis> diagnose({
    required String vehicleName,
    required String vehicleType,
    required String problem,
    required List<String> symptoms,
  }) async {
    final raw = await _repository.diagnoseVehicle(
      vehicleType: vehicleType,
      problem: problem,
      symptoms: symptoms,
    );
    return parseDiagnosis(raw, vehicleName: vehicleName);
  }

  /// Parses a raw diagnosis map into [Diagnosis]. Throws [FormatException]
  /// when required fields are missing or malformed.
  Diagnosis parseDiagnosis(
    Map<String, dynamic> raw, {
    required String vehicleName,
  }) {
    final id = raw['id'] as String? ?? 'diag-unknown';
    final vehicleType = raw['vehicle_type'] as String? ?? vehicleName;
    final problem = raw['problem'] as String? ?? 'General issue';
    final symptoms = (raw['symptoms'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    final causes = (raw['possible_causes'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();

    final severity = _parseSeverity(raw['severity'] as String?);
    final estimatedCost = (raw['estimated_cost'] as num?)?.toDouble() ?? 0;
    final recommendedAction =
        raw['recommended_action'] as String? ?? 'Get the vehicle inspected.';
    final shouldDrive = raw['should_drive'] as bool? ?? true;
    final recommendedService =
        raw['recommended_service'] as String? ?? 'General Inspection';
    final confidence = (raw['confidence'] as num?)?.toInt() ?? 0;
    final timestamp = DateTime.tryParse(
            raw['timestamp'] as String? ?? '') ??
        DateTime.now();

    if (causes.isEmpty) {
      throw const FormatException('Diagnosis payload has no possible causes');
    }

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
