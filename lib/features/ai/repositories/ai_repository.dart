import 'dart:async';
import '../models/models.dart';

/// Thrown by the mock AI backend when it simulates a network failure.
class AiNetworkException implements Exception {
  final String message;
  const AiNetworkException([this.message = '']);

  @override
  String toString() => message.isNotEmpty
      ? message
      : 'AI service is temporarily unreachable. Please try again.';
}

/// Mock AI backend.
///
/// Sprint 1.9 serves a seeded, in-memory knowledge base with simulated network
/// latency so the UI behaves exactly like production. It also supports a
/// deterministic failure injection (`failForFirstCalls`) so the error / retry
/// paths can be exercised by tests. Sprint 2 swaps the internals for the real
/// Gemini/OpenAI client — the provider, services and screens never change
/// because they depend only on this interface.
class AiRepository {
  static const Duration defaultLatency = Duration(milliseconds: 900);

  final Duration latency;
  final int failForFirstCalls;
  final List<Conversation> _conversations = [];

  int _callCount = 0;
  int _diagnosisCounter = 0;

  AiRepository({
    this.latency = defaultLatency,
    this.failForFirstCalls = 0,
  }) {
    _seed();
  }

  // ── Failure + latency simulation ───────────────────────────────────────

  Future<T> _call<T>(T Function() body) async {
    await Future<void>.delayed(latency);
    if (failForFirstCalls > 0 && _callCount < failForFirstCalls) {
      _callCount++;
      throw const AiNetworkException(
        'Could not reach the AI service. Check your connection and retry.',
      );
    }
    _callCount++;
    return body();
  }

  // ── Seed data ──────────────────────────────────────────────────────────

  void _seed() {
    final now = DateTime.now();

    final starterConversation = Conversation(
      id: 'ai-0001',
      title: 'Engine overheating',
      createdAt: now.subtract(const Duration(hours: 26)),
      updatedAt: now.subtract(const Duration(hours: 25)),
      isPinned: true,
      messages: [
        ChatMessage(
          id: 'm-0001',
          role: MessageRole.user,
          content: 'My engine is overheating while riding in traffic.',
          timestamp: now.subtract(const Duration(hours: 26)),
        ),
        ChatMessage(
          id: 'm-0002',
          role: MessageRole.assistant,
          content: 'Engine overheating is usually caused by coolant, airflow or '
              'thermostat issues.',
          timestamp: now.subtract(const Duration(hours: 26, minutes: 1)),
          response: const AiResponse(
            blocks: [
              AiBlock(
                type: AiBlockType.warning,
                text: 'Stop the vehicle, switch the engine off and let it cool '
                    'before checking anything.',
              ),
              AiBlock(
                type: AiBlockType.bulletList,
                title: 'Likely causes',
                items: [
                  'Low or leaked coolant',
                  'Faulty thermostat stuck closed',
                  'Blocked radiator or fan not spinning',
                  'Water pump failure',
                ],
              ),
              AiBlock(
                type: AiBlockType.recommendation,
                text: 'Refill coolant to the correct level, check the radiator '
                    'fan, and get the thermostat inspected within 50 km.',
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
        ),
      ],
    );

    final batteryConversation = Conversation(
      id: 'ai-0002',
      title: 'Battery not holding charge',
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(hours: 3)),
      isPinned: true,
      messages: [
        ChatMessage(
          id: 'm-0011',
          role: MessageRole.user,
          content: 'My battery drains overnight even after a new charge.',
          timestamp: now.subtract(const Duration(days: 2)),
        ),
        ChatMessage(
          id: 'm-0012',
          role: MessageRole.assistant,
          content: 'A battery that drains overnight points to a parasitic draw '
              'or a weak charging system.',
          timestamp: now.subtract(const Duration(days: 2, minutes: 1)),
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
                text: 'If all three are fine, ask the service centre to test the '
                    'alternator output — a failing regulator is the common '
                    'cause of overnight drain.',
              ),
            ],
          ),
        ),
      ],
    );

    final brakeConversation = Conversation(
      id: 'ai-0003',
      title: 'Brake noise',
      createdAt: now.subtract(const Duration(days: 4)),
      updatedAt: now.subtract(const Duration(days: 1)),
      messages: [
        ChatMessage(
          id: 'm-0021',
          role: MessageRole.user,
          content: 'Brakes make a squealing noise when I slow down.',
          timestamp: now.subtract(const Duration(days: 4)),
        ),
        ChatMessage(
          id: 'm-0022',
          role: MessageRole.assistant,
          content: 'Squealing at low speed is the classic sign of worn brake '
              'pads reaching the wear indicator.',
          timestamp: now.subtract(const Duration(days: 4, minutes: 1)),
          response: const AiResponse(
            blocks: [
              AiBlock(
                type: AiBlockType.bulletList,
                title: 'Possible causes',
                items: [
                  'Worn brake pads (most common)',
                  'Dust or grit between pad and disc',
                  'Glazed pad surface after hard braking',
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
            ],
          ),
        ),
      ],
    );

    final fuelConversation = Conversation(
      id: 'ai-0004',
      title: 'Fuel efficiency dropped',
      createdAt: now.subtract(const Duration(days: 6)),
      updatedAt: now.subtract(const Duration(days: 5)),
      messages: [
        ChatMessage(
          id: 'm-0031',
          role: MessageRole.user,
          content: 'My mileage has dropped suddenly.',
          timestamp: now.subtract(const Duration(days: 6)),
        ),
        ChatMessage(
          id: 'm-0032',
          role: MessageRole.assistant,
          content: 'A sudden drop in mileage is usually tyre pressure, a dirty '
              'air filter or aggressive riding.',
          timestamp: now.subtract(const Duration(days: 6, minutes: 1)),
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
                text: 'Keep tyre pressure at the level in your owner manual and '
                    'service the air filter every 5,000 km.',
              ),
            ],
            actions: [
              AiActionButton(
                label: 'Fuel Recommendation',
                action: AiAction.fuelRecommendation,
              ),
            ],
          ),
        ),
      ],
    );

    final oilConversation = Conversation(
      id: 'ai-0005',
      title: 'Oil change interval',
      createdAt: now.subtract(const Duration(days: 12)),
      updatedAt: now.subtract(const Duration(days: 11)),
      messages: [
        ChatMessage(
          id: 'm-0041',
          role: MessageRole.user,
          content: 'When should I change my synthetic engine oil?',
          timestamp: now.subtract(const Duration(days: 12)),
        ),
        ChatMessage(
          id: 'm-0042',
          role: MessageRole.assistant,
          content: 'For a Honda Activa 6G, fully synthetic oil is recommended '
              'every 5,000 km or 6 months, whichever comes first.',
          timestamp: now.subtract(const Duration(days: 12, minutes: 1)),
          response: const AiResponse(
            blocks: [
              AiBlock(
                type: AiBlockType.recommendation,
                text: 'Change synthetic engine oil every 5,000 km (or 6 '
                    'months), and replace the oil filter every second change.',
              ),
            ],
            actions: [
              AiActionButton(
                label: 'Book a Service',
                action: AiAction.bookMechanic,
              ),
            ],
          ),
        ),
      ],
    );

    _conversations.addAll([
      starterConversation,
      batteryConversation,
      brakeConversation,
      fuelConversation,
      oilConversation,
    ]);
  }

  // ── API surface (all async, all latency/failure aware) ─────────────────

  /// Returns the full seeded conversation list (newest activity first).
  Future<List<Conversation>> fetchConversations() {
    return _call(() {
      final sorted = [..._conversations]..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return sorted;
    });
  }

  /// Sends a message to the mock model and returns the raw assistant reply.
  Future<String> sendMessage(String conversationId, String message) {
    return _call(() => _composeRawReply(message));
  }

  /// Runs the mock diagnostic engine and returns a raw structured payload
  /// (the shape a real backend would return). [DiagnosisService] parses it.
  Future<Map<String, dynamic>> diagnoseVehicle({
    required String vehicleType,
    required String problem,
    required List<String> symptoms,
  }) {
    return _call(() {
      final key = problem.toLowerCase();
      final base = _diagnosisTemplate(problem, key);
      _diagnosisCounter++;
      return {
        'id': 'diag-$_diagnosisCounter',
        'vehicle_name': '$_displayVehicle(vehicleType)',
        'vehicle_type': vehicleType,
        'problem': problem,
        'symptoms': symptoms,
        ...base,
        'timestamp': DateTime.now().toIso8601String(),
      };
    });
  }

  String _displayVehicle(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'bike':
        return 'Honda Activa 6G';
      case 'car':
        return 'Maruti Alto 800';
      case 'scooter':
        return 'TVS Jupiter';
      default:
        return 'Electric vehicle';
    }
  }

  // ── Raw reply + knowledge base ─────────────────────────────────────────

  String _composeRawReply(String message) {
    final text = message.toLowerCase();

    if (text.contains('diagnos') || text.contains('won\'t start') ||
        text.contains('wont start') || text.contains('not start')) {
      return 'I can help with that. Start the guided diagnosis so I can '
          'collect the symptoms and give you a structured result.';
    }
    if (text.contains('battery') || text.contains('charge')) {
      return 'Battery issues usually come from age, a parasitic draw, or the '
          'charging system. Here is a quick checklist to run first.';
    }
    if (text.contains('brake')) {
      return 'Brake noise is most often worn pads or grit on the disc. Here '
          'is what to check and an honest cost range.';
    }
    if (text.contains('fuel') || text.contains('mileage') ||
        text.contains('efficiency')) {
      return 'Mileage drops are usually tyre pressure, a dirty air filter or '
          'spark plugs. Let me walk you through the checks.';
    }
    if (text.contains('oil')) {
      return 'Synthetic engine oil should be changed every 5,000 km or 6 '
          'months. Here is my recommendation.';
    }
    if (text.contains('overheat')) {
      return 'Overheating is serious. Stop, switch off, and let the engine '
          'cool before inspecting coolant and airflow.';
    }
    if (text.contains('tyre') || text.contains('tire') || text.contains('flat')) {
      return 'A flat or damaged tyre is unsafe to ride. Check the pressure '
          'and look for cuts or bulges before considering a replacement.';
    }
    if (text.contains('warning')) {
      return 'A warning light should never be ignored. I can help decode it — '
          'start with the guided diagnosis for a structured answer.';
    }
    if (text.contains('service') || text.contains('maintenance')) {
      return 'Here is a simple maintenance schedule for your vehicle, grouped '
          'by distance.';
    }
    return 'Here is what I found for that. If you tell me more about the '
        'symptoms, I can give you a structured diagnosis with causes, '
        'severity and cost.';
  }

  /// Keyword → diagnosis knowledge base. Falls back to a generic template so
  /// the mock engine always returns a useful, structured result.
  Map<String, dynamic> _diagnosisTemplate(String problem, String key) {
    if (key.contains('start')) {
      return _template(
        severity: 'high',
        causes: [
          'Flat or weak battery',
          'Faulty starter relay',
          'Clogged fuel filter',
          'Spark plug failure',
        ],
        cost: 1200,
        action: 'Try a jump start once. If it clicks but will not turn, the '
            'starter relay or battery needs attention.',
        drive: false,
        service: 'Battery & Starting System Service',
        confidence: 86,
      );
    }
    if (key.contains('overheat')) {
      return _template(
        severity: 'high',
        causes: [
          'Low coolant level',
          'Thermostat stuck closed',
          'Blocked radiator / cooling fan failure',
          'Water pump fault',
        ],
        cost: 1800,
        action: 'Stop immediately, let the engine cool, and top up coolant. '
            'Do not open the radiator cap while hot.',
        drive: false,
        service: 'Cooling System Service',
        confidence: 90,
      );
    }
    if (key.contains('brake') || key.contains('noise')) {
      return _template(
        severity: 'medium',
        causes: [
          'Worn brake pads',
          'Grit or dust between pad and disc',
          'Glazed pad surface',
        ],
        cost: 1200,
        action: 'Inspect pad thickness. Replace if below 2 mm.',
        drive: true,
        service: 'Brake Pad Replacement & Inspection',
        confidence: 84,
      );
    }
    if (key.contains('battery')) {
      return _template(
        severity: 'medium',
        causes: [
          'Battery age beyond 3 years',
          'Parasitic electrical draw',
          'Failing regulator / alternator',
        ],
        cost: 1800,
        action: 'Test the battery with a load tester, then check the charging '
            'output at idle.',
        drive: true,
        service: 'Battery Health Check & Replacement',
        confidence: 82,
      );
    }
    if (key.contains('mileage') || key.contains('fuel') ||
        key.contains('efficiency')) {
      return _template(
        severity: 'low',
        causes: [
          'Low tyre pressure',
          'Dirty air filter',
          'Old spark plugs',
          'Stiff chain / brakes dragging',
        ],
        cost: 400,
        action: 'Inflate tyres to spec, clean the air filter, and service '
            'chain tension.',
        drive: true,
        service: 'Tune-Up & Efficiency Check',
        confidence: 78,
      );
    }
    if (key.contains('oil') || key.contains('leak')) {
      return _template(
        severity: 'medium',
        causes: [
          'Old engine oil (overdue)',
          'Oil seal leak',
          'Loosened drain plug',
        ],
        cost: 600,
        action: 'Check the dipstick level and look under the vehicle for '
            'drips. Book an oil change.',
        drive: true,
        service: 'Engine Oil Change & Leak Inspection',
        confidence: 80,
      );
    }
    if (key.contains('tyre') || key.contains('tire') || key.contains('flat')) {
      return _template(
        severity: 'high',
        causes: [
          'Puncture or nail in tread',
          'Valve leak',
          'Cracked sidewall',
        ],
        cost: 900,
        action: 'Check pressure and inspect for cuts. Do not ride a flat tyre.',
        drive: false,
        service: 'Tyre Repair / Replacement',
        confidence: 85,
      );
    }
    return _template(
      severity: 'medium',
      causes: ['Inspect the affected part for visible wear or damage'],
      cost: 800,
      action: 'Have a mechanic confirm the cause before replacing parts.',
      drive: true,
      service: 'General Inspection',
      confidence: 70,
    );
  }

  Map<String, dynamic> _template({
    required String severity,
    required List<String> causes,
    required double cost,
    required String action,
    required bool drive,
    required String service,
    required int confidence,
  }) {
    return {
      'possible_causes': causes,
      'severity': severity,
      'estimated_cost': cost,
      'recommended_action': action,
      'should_drive': drive,
      'recommended_service': service,
      'confidence': confidence,
    };
  }
}
