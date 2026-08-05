import '../models/models.dart';
import '../repositories/ai_repository.dart';

/// A composed assistant answer: the plain-text reply plus its structured
/// blocks and action buttons.
class AssistantReply {
  final String text;
  final AiResponse response;

  const AssistantReply({required this.text, required this.response});
}

/// Intent classification used to frame a reply with the right blocks.
enum _Intent {
  diagnosis,
  battery,
  brake,
  fuel,
  oil,
  overheat,
  tyre,
  warning,
  maintenance,
  generic,
}

/// Orchestrates assistant replies.
///
/// The [AiService] sits between the provider and the [AiRepository] (same
/// shape as the Fuel module's service layer): it calls the mock backend for
/// the raw reply, then frames a premium, structured [AssistantReply] with
/// blocks and action buttons. In Sprint 2 only this class changes — the
/// provider and screens keep consuming [AssistantReply].
class AiService {
  final AiRepository _repository;

  AiService({AiRepository? repository})
      : _repository = repository ?? AiRepository();

  /// Sends [userText] to the mock model and composes the structured reply.
  Future<AssistantReply> generateResponse(String userText) async {
    final raw = await _repository.sendMessage('', userText);
    final intent = _classify(userText);
    final reply = _buildReply(intent, raw);
    return AssistantReply(text: reply.text, response: reply.response);
  }

  _Intent _classify(String text) {
    final t = text.toLowerCase();
    if (t.contains('diagnos') || t.contains('won\'t start') ||
        t.contains('wont start') || t.contains('not start')) {
      return _Intent.diagnosis;
    }
    if (t.contains('battery') || t.contains('charge')) return _Intent.battery;
    if (t.contains('brake')) return _Intent.brake;
    if (t.contains('overheat')) return _Intent.overheat;
    if (t.contains('tyre') || t.contains('tire') || t.contains('flat')) {
      return _Intent.tyre;
    }
    if (t.contains('oil')) return _Intent.oil;
    if (t.contains('warning')) return _Intent.warning;
    if (t.contains('fuel') || t.contains('mileage') ||
        t.contains('efficiency')) {
      return _Intent.fuel;
    }
    if (t.contains('service') || t.contains('maintenance')) {
      return _Intent.maintenance;
    }
    return _Intent.generic;
  }

  _Reply _buildReply(_Intent intent, String raw) {
    switch (intent) {
      case _Intent.diagnosis:
        return _Reply(
          text: raw,
          response: const AiResponse(
            blocks: [
              AiBlock(
                type: AiBlockType.warning,
                text: 'Starting trouble needs a structured check before '
                    'replacing any parts.',
              ),
              AiBlock(
                type: AiBlockType.recommendation,
                text: 'Use the guided diagnosis to capture the exact symptoms '
                    '— I will return causes, severity, cost and whether it is '
                    'safe to drive.',
              ),
            ],
            actions: [
              AiActionButton(
                label: 'Start Guided Diagnosis',
                action: AiAction.openDiagnosis,
              ),
            ],
          ),
        );
      case _Intent.battery:
        return _Reply(
          text: raw,
          response: const AiResponse(
            blocks: [
              AiBlock(
                type: AiBlockType.checklist,
                title: 'Quick checks',
                items: [
                  'Are lights or accessories left on?',
                  'Is the terminal clamp tight and clean?',
                  'Does the battery case look swollen?',
                ],
              ),
              AiBlock(
                type: AiBlockType.text,
                text: 'If all three are fine, test the charging output at '
                    'idle — a failing regulator is the common cause of '
                    'overnight drain.',
              ),
            ],
            actions: [
              AiActionButton(
                label: 'Book a Battery Check',
                action: AiAction.bookMechanic,
              ),
            ],
          ),
        );
      case _Intent.brake:
        return _Reply(
          text: raw,
          response: const AiResponse(
            blocks: [
              AiBlock(
                type: AiBlockType.bulletList,
                title: 'Possible causes',
                items: [
                  'Worn brake pads (most common)',
                  'Dust or grit between pad and disc',
                  'Glazed pad surface',
                ],
              ),
              AiBlock(
                type: AiBlockType.costEstimate,
                title: 'Estimated cost',
                items: ['Pad replacement', 'Disc inspection'],
                note: '₹800 – ₹1,500 depending on the model',
              ),
            ],
            actions: [
              AiActionButton(
                label: 'Search Parts',
                action: AiAction.searchParts,
              ),
              AiActionButton(
                label: 'Book a Mechanic',
                action: AiAction.bookMechanic,
              ),
            ],
          ),
        );
      case _Intent.overheat:
        return _Reply(
          text: raw,
          response: const AiResponse(
            blocks: [
              AiBlock(
                type: AiBlockType.warning,
                text: 'Stop the vehicle, switch the engine off and let it '
                    'cool before checking anything.',
              ),
              AiBlock(
                type: AiBlockType.bulletList,
                title: 'Likely causes',
                items: [
                  'Low or leaked coolant',
                  'Thermostat stuck closed',
                  'Blocked radiator or fan not spinning',
                  'Water pump failure',
                ],
              ),
              AiBlock(
                type: AiBlockType.recommendation,
                text: 'Refill coolant to the correct level and get the cooling '
                    'system inspected within 50 km.',
              ),
            ],
            actions: [
              AiActionButton(
                label: 'Run Guided Diagnosis',
                action: AiAction.openDiagnosis,
              ),
              AiActionButton(
                label: 'Book a Mechanic',
                action: AiAction.bookMechanic,
              ),
            ],
          ),
        );
      case _Intent.tyre:
        return _Reply(
          text: raw,
          response: const AiResponse(
            blocks: [
              AiBlock(
                type: AiBlockType.warning,
                text: 'Do not ride on a flat or visibly damaged tyre.',
              ),
              AiBlock(
                type: AiBlockType.bulletList,
                title: 'Likely causes',
                items: [
                  'Puncture or nail in the tread',
                  'Valve leak',
                  'Cracked sidewall',
                ],
              ),
              AiBlock(
                type: AiBlockType.costEstimate,
                title: 'Estimated cost',
                items: ['Puncture repair', 'Tyre replacement'],
                note: '₹150 – ₹1,800 depending on the tyre',
              ),
            ],
            actions: [
              AiActionButton(
                label: 'Search Parts',
                action: AiAction.searchParts,
              ),
              AiActionButton(
                label: 'Book a Mechanic',
                action: AiAction.bookMechanic,
              ),
            ],
          ),
        );
      case _Intent.oil:
        return _Reply(
          text: raw,
          response: const AiResponse(
            blocks: [
              AiBlock(
                type: AiBlockType.recommendation,
                text: 'Change synthetic engine oil every 5,000 km (or 6 '
                    'months), and replace the oil filter every second change.',
              ),
              AiBlock(
                type: AiBlockType.costEstimate,
                title: 'Estimated cost',
                items: ['Synthetic oil', 'Oil filter', 'Labour'],
                note: '₹550 – ₹1,000',
              ),
            ],
            actions: [
              AiActionButton(
                label: 'Book an Oil Change',
                action: AiAction.bookMechanic,
              ),
            ],
          ),
        );
      case _Intent.warning:
        return _Reply(
          text: raw,
          response: const AiResponse(
            blocks: [
              AiBlock(
                type: AiBlockType.recommendation,
                text: 'A warning light should never be ignored. Note when it '
                    'appears and capture the symptoms in a guided diagnosis '
                    'for a structured answer.',
              ),
            ],
            actions: [
              AiActionButton(
                label: 'Decode Warning Light',
                action: AiAction.openDiagnosis,
              ),
            ],
          ),
        );
      case _Intent.fuel:
        return _Reply(
          text: raw,
          response: const AiResponse(
            blocks: [
              AiBlock(
                type: AiBlockType.bulletList,
                title: 'Check in order',
                items: [
                  'Tyre pressure (both tyres)',
                  'Air filter cleanliness',
                  'Spark plug condition',
                  'Chain lubrication',
                ],
              ),
              AiBlock(
                type: AiBlockType.recommendation,
                text: 'Keep tyre pressure at the level in your owner manual '
                    'and service the air filter every 5,000 km.',
              ),
            ],
            actions: [
              AiActionButton(
                label: 'Fuel Recommendation',
                action: AiAction.fuelRecommendation,
              ),
            ],
          ),
        );
      case _Intent.maintenance:
        return _Reply(
          text: raw,
          response: const AiResponse(
            blocks: [
              AiBlock(
                type: AiBlockType.checklist,
                title: 'Maintenance schedule',
                items: [
                  'Every 1,000 km — chain lube & tyre pressure',
                  'Every 3,000 km — engine oil check',
                  'Every 5,000 km — oil change & air filter',
                  'Every 10,000 km — spark plugs & brake inspection',
                ],
              ),
            ],
            actions: [
              AiActionButton(
                label: 'Book a Service',
                action: AiAction.bookMechanic,
              ),
            ],
          ),
        );
      case _Intent.generic:
        return _Reply(
          text: raw,
          response: const AiResponse(
            blocks: [
              AiBlock(
                type: AiBlockType.text,
                text: 'Tell me more about the symptoms and I can give you a '
                    'structured diagnosis with causes, severity, cost and '
                    'whether it is safe to drive.',
              ),
              AiBlock(
                type: AiBlockType.bulletList,
                title: 'Try asking about',
                items: [
                  'My bike won\'t start',
                  'Engine overheating',
                  'Brake noise',
                  'Battery problem',
                ],
              ),
            ],
            actions: [
              AiActionButton(
                label: 'Guided Diagnosis',
                action: AiAction.openDiagnosis,
              ),
            ],
          ),
        );
    }
  }
}

class _Reply {
  final String text;
  final AiResponse response;

  const _Reply({required this.text, required this.response});
}
