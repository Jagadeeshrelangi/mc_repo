import 'package:flutter/material.dart';
import '../models/models.dart';
import '../repositories/ai_repository.dart';
import '../services/ai_service.dart';
import '../services/diagnosis_service.dart';

/// Overall screen state for AI surfaces that load remote data.
enum AiScreenState { initial, loading, ready, error }

/// Mock vehicle health summary shown on the AI home.
class VehicleHealth {
  final String vehicleName;
  final int score;
  final String statusLabel;
  final String nextService;

  const VehicleHealth({
    required this.vehicleName,
    required this.score,
    required this.statusLabel,
    required this.nextService,
  });
}

/// Single source of truth for the AI Assistant module.
///
/// Owns conversations, the current thread, sending/typing state, errors and
/// retry, suggestions, quick actions and the guided diagnosis lifecycle.
///
/// There is exactly ONE conversation store: [_conversations]. [currentConversation]
/// and [messages] are derived views — nothing mirrors the thread, so the badge,
/// list and chat can never disagree.
class AiProvider extends ChangeNotifier {
  final AiRepository _repository;
  final AiService _aiService;
  final DiagnosisService _diagnosisService;

  AiProvider({
    AiRepository? repository,
    AiService? aiService,
    DiagnosisService? diagnosisService,
  }) : this._(repository ?? AiRepository(), aiService, diagnosisService);

  AiProvider._(
    this._repository,
    AiService? aiService,
    DiagnosisService? diagnosisService,
  ) : _aiService = aiService ?? AiService(repository: _repository),
      _diagnosisService =
          diagnosisService ?? DiagnosisService(repository: _repository);

  // ── Home state ─────────────────────────────────────────────────────────
  AiScreenState _state = AiScreenState.initial;
  AiScreenState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  // ── Conversation store (single source of truth) ───────────────────────
  final List<Conversation> _conversations = [];
  String? _currentConversationId;

  int _messageCounter = 0;
  int _conversationCounter = 0;

  /// All conversations, newest activity first (pinned threads float to top).
  List<Conversation> get conversations {
    final sorted = [..._conversations]..sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return List.unmodifiable(sorted);
  }

  List<Conversation> get pinnedConversations =>
      conversations.where((c) => c.isPinned).toList();

  List<Conversation> get recentConversations =>
      conversations.where((c) => !c.isPinned).take(5).toList();

  Conversation? get currentConversation {
    if (_currentConversationId == null) return null;
    for (final c in _conversations) {
      if (c.id == _currentConversationId) return c;
    }
    return null;
  }

  bool get hasActiveChat =>
      currentConversation != null && currentConversation!.messages.isNotEmpty;

  List<ChatMessage> get messages =>
      currentConversation?.messages ?? const <ChatMessage>[];

  String? get currentConversationId => _currentConversationId;

  // ── Sending / typing / retry ───────────────────────────────────────────
  bool _isSending = false;
  bool get isSending => _isSending;

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  String? _lastFailedUserText;
  String? get lastFailedUserText => _lastFailedUserText;

  // ── Diagnosis ──────────────────────────────────────────────────────────
  bool _isDiagnosing = false;
  bool get isDiagnosing => _isDiagnosing;

  String? _diagnosisError;
  String? get diagnosisError => _diagnosisError;

  Diagnosis? _lastDiagnosis;
  Diagnosis? get lastDiagnosis => _lastDiagnosis;

  final List<Diagnosis> _recentDiagnoses = [];
  List<Diagnosis> get recentDiagnoses => List.unmodifiable(_recentDiagnoses);

  // ── Static assistant content ───────────────────────────────────────────
  static const List<SuggestedQuestion> suggestions = [
    SuggestedQuestion(id: 's-1', text: 'My bike won\'t start'),
    SuggestedQuestion(id: 's-2', text: 'Engine overheating'),
    SuggestedQuestion(id: 's-3', text: 'Brake noise'),
    SuggestedQuestion(id: 's-4', text: 'Battery problem'),
    SuggestedQuestion(id: 's-5', text: 'Oil leak'),
    SuggestedQuestion(id: 's-6', text: 'Fuel efficiency'),
    SuggestedQuestion(id: 's-7', text: 'Flat tyre'),
    SuggestedQuestion(id: 's-8', text: 'Engine warning light'),
  ];

  static const List<String> tips = [
    'Check tyre pressure every week — it saves fuel and avoids blowouts.',
    'A clicking sound when starting usually means a weak battery, not the '
        'starter motor.',
    'Brake squeal is your pads telling you they are thin. Check them early.',
  ];

  static const VehicleHealth vehicleHealth = VehicleHealth(
    vehicleName: 'Honda Activa 6G',
    score: 92,
    statusLabel: 'Healthy',
    nextService: 'Oil change due in 400 km',
  );

  final List<QuickAction> quickActions = const [
    QuickAction(
      id: 'qa-diagnosis',
      title: 'Vehicle Diagnosis',
      subtitle: 'Guided symptom check',
      icon: Icons.build_circle_rounded,
      prompt: 'Help me diagnose my vehicle.',
      destination: QuickActionDestination.diagnosis,
    ),
    QuickAction(
      id: 'qa-mechanic',
      title: 'Find Mechanic',
      subtitle: 'Nearby experts',
      icon: Icons.support_agent_rounded,
      prompt: 'Find a mechanic near me.',
      destination: QuickActionDestination.mechanic,
    ),
    QuickAction(
      id: 'qa-fuel',
      title: 'Fuel Recommendation',
      subtitle: 'Best fuel for your ride',
      icon: Icons.local_gas_station_rounded,
      prompt: 'What fuel should I use for better mileage?',
      destination: QuickActionDestination.fuel,
    ),
    QuickAction(
      id: 'qa-marketplace',
      title: 'Marketplace Help',
      subtitle: 'Parts, oils, tyres',
      icon: Icons.storefront_rounded,
      prompt: 'Help me find parts in the marketplace.',
      destination: QuickActionDestination.marketplace,
    ),
    QuickAction(
      id: 'qa-maintenance',
      title: 'Maintenance Tips',
      subtitle: 'Keep your ride healthy',
      icon: Icons.calendar_month_rounded,
      prompt: 'Give me maintenance tips for my vehicle.',
      destination: QuickActionDestination.chat,
    ),
    QuickAction(
      id: 'qa-battery',
      title: 'Battery Problems',
      subtitle: 'Drain, charge, terminals',
      icon: Icons.battery_charging_full_rounded,
      prompt: 'My battery is not holding charge.',
      destination: QuickActionDestination.chat,
    ),
    QuickAction(
      id: 'qa-engine',
      title: 'Engine Problems',
      subtitle: 'Noise, idle, misfire',
      icon: Icons.engineering_rounded,
      prompt: 'My engine is making strange noises.',
      destination: QuickActionDestination.chat,
    ),
    QuickAction(
      id: 'qa-tyre',
      title: 'Tyre Problems',
      subtitle: 'Pressure, wear, flat',
      icon: Icons.tire_repair_rounded,
      prompt: 'My tyre looks low and feels flat.',
      destination: QuickActionDestination.chat,
    ),
    QuickAction(
      id: 'qa-emergency',
      title: 'Emergency Help',
      subtitle: 'SOS numbers & advice',
      icon: Icons.emergency_rounded,
      prompt: 'I need emergency roadside help.',
      destination: QuickActionDestination.emergency,
    ),
  ];

  // ── Home boot ──────────────────────────────────────────────────────────

  Future<void> loadHome() async {
    if (_state == AiScreenState.loading) return;
    _state = AiScreenState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _repository.fetchConversations();
      _mergeReloaded(loaded);
      _state = AiScreenState.ready;
    } catch (e) {
      _state = AiScreenState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Pull-to-refresh: keeps the current list visible while reloading.
  Future<void> refreshHome() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      final loaded = await _repository.fetchConversations();
      _mergeReloaded(loaded);
      _state = AiScreenState.ready;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Replaces the seeded conversations with the freshly loaded ones while
  /// preserving anything the user created during this session (new threads,
  /// messages and pin overrides must never be wiped by a refresh).
  void _mergeReloaded(List<Conversation> loaded) {
    final previousById = {for (final c in _conversations) c.id: c};
    final loadedIds = loaded.map((c) => c.id).toSet();

    final refreshedSeeds =
        loaded.map((c) {
          final previous = previousById[c.id];
          if (previous != null && previous.isPinned != c.isPinned) {
            return c.copyWith(isPinned: previous.isPinned);
          }
          return c;
        }).toList();

    final userCreated =
        _conversations.where((c) => !loadedIds.contains(c.id)).toList();

    _conversations
      ..clear()
      ..addAll(refreshedSeeds)
      ..addAll(userCreated);
  }

  // ── Conversation lifecycle ─────────────────────────────────────────────

  void newConversation() {
    _currentConversationId = null;
    _errorMessage = null;
    _lastFailedUserText = null;
    notifyListeners();
  }

  void openConversation(String conversationId) {
    _currentConversationId = conversationId;
    _errorMessage = null;
    _lastFailedUserText = null;
    notifyListeners();
  }

  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);
    if (_currentConversationId == conversationId) {
      _currentConversationId = null;
    }
    notifyListeners();
  }

  Future<void> renameConversation(String conversationId, String title) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0) return;
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _conversations[index] = _conversations[index].copyWith(title: trimmed);
    notifyListeners();
  }

  void togglePin(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0) return;
    final current = _conversations[index];
    _conversations[index] = current.copyWith(isPinned: !current.isPinned);
    notifyListeners();
  }

  Future<void> clearAllConversations() async {
    _conversations.clear();
    _currentConversationId = null;
    _errorMessage = null;
    _lastFailedUserText = null;
    notifyListeners();
  }

  List<Conversation> searchConversations(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return conversations;
    return conversations
        .where(
          (c) =>
              c.title.toLowerCase().contains(q) ||
              c.preview.toLowerCase().contains(q),
        )
        .toList();
  }

  // ── Chat ───────────────────────────────────────────────────────────────

  /// Appends the user message and streams the assistant reply.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    final now = DateTime.now();
    final userMessage = ChatMessage(
      id: _nextMessageId(),
      role: MessageRole.user,
      content: trimmed,
      timestamp: now,
    );

    if (_currentConversationId == null) {
      final conversation = Conversation(
        id: _nextConversationId(),
        title: _defaultTitle(trimmed),
        createdAt: now,
        updatedAt: now,
        messages: [userMessage],
      );
      _conversations.insert(0, conversation);
      _currentConversationId = conversation.id;
    } else {
      _appendToCurrent(userMessage);
    }

    await _requestAssistant(trimmed);
  }

  /// Re-sends the last failed user message without duplicating it.
  Future<void> retryLast() async {
    final text = _lastFailedUserText;
    if (text == null || _isSending) return;
    await _requestAssistant(text);
  }

  /// Re-runs the last exchange, replacing the previous assistant reply.
  Future<void> regenerateLast() async {
    if (_isSending) return;
    final conversation = currentConversation;
    if (conversation == null || conversation.messages.isEmpty) return;
    final last = conversation.messages.last;
    if (last.isUser) return;

    String? lastUserText;
    for (final message in conversation.messages.reversed) {
      if (message.isUser) {
        lastUserText = message.content;
        break;
      }
    }
    if (lastUserText == null) return;

    _replaceCurrent(
      conversation.copyWith(
        messages: conversation.messages.sublist(
          0,
          conversation.messages.length - 1,
        ),
      ),
    );
    notifyListeners();
    await _requestAssistant(lastUserText);
  }

  Future<void> _requestAssistant(String userText) async {
    _errorMessage = null;
    _lastFailedUserText = null;
    _isSending = true;
    _isTyping = true;
    notifyListeners();

    try {
      final reply = await _aiService.generateResponse(userText);
      _appendToCurrent(
        ChatMessage(
          id: _nextMessageId(),
          role: MessageRole.assistant,
          content: reply.text,
          timestamp: DateTime.now(),
          response: reply.response,
        ),
      );
    } catch (e) {
      _errorMessage = e.toString();
      _lastFailedUserText = userText;
    } finally {
      _isSending = false;
      _isTyping = false;
      notifyListeners();
    }
  }

  // ── Diagnosis ──────────────────────────────────────────────────────────

  /// Runs the guided diagnosis. Returns the result (or null on failure).
  Future<Diagnosis?> startDiagnosis({
    required String vehicleName,
    required String vehicleType,
    required String problem,
    required List<String> symptoms,
  }) async {
    if (_isDiagnosing) return null;
    if (symptoms.isEmpty) {
      _diagnosisError = 'Select at least one symptom to diagnose.';
      notifyListeners();
      return null;
    }

    _isDiagnosing = true;
    _diagnosisError = null;
    notifyListeners();

    try {
      final diagnosis = await _diagnosisService.diagnose(
        vehicleName: vehicleName,
        vehicleType: vehicleType,
        problem: problem,
        symptoms: symptoms,
      );
      _lastDiagnosis = diagnosis;
      _recentDiagnoses.removeWhere((d) => d.id == diagnosis.id);
      _recentDiagnoses.insert(0, diagnosis);
      if (_recentDiagnoses.length > 4) {
        _recentDiagnoses.removeRange(4, _recentDiagnoses.length);
      }
      return diagnosis;
    } catch (e) {
      _diagnosisError = e.toString();
      return null;
    } finally {
      _isDiagnosing = false;
      notifyListeners();
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────

  void _appendToCurrent(ChatMessage message) {
    final conversation = currentConversation;
    if (conversation == null) return;
    _replaceCurrent(
      conversation.copyWith(
        messages: [...conversation.messages, message],
        updatedAt: message.timestamp,
      ),
    );
  }

  void _replaceCurrent(Conversation updated) {
    final index = _conversations.indexWhere((c) => c.id == updated.id);
    if (index >= 0) {
      _conversations[index] = updated;
    }
  }

  String _defaultTitle(String firstMessage) {
    final clean = firstMessage.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 42) return clean;
    return '${clean.substring(0, 42)}…';
  }

  String _nextMessageId() =>
      'm-${DateTime.now().microsecondsSinceEpoch}-${_messageCounter++}';

  String _nextConversationId() =>
      'ai-${DateTime.now().microsecondsSinceEpoch}-${_conversationCounter++}';
}
