import 'package:flutter/material.dart';
import 'package:mecha_connect/services/ai_repository.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/diagnosis_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/thinking_indicator.dart';
import '../widgets/chat_input.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_helpers.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => ChatBotState();
}

class ChatBotState extends State<ChatBot> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIRepository _aiRepository = AIRepository();

  final List<Map<String, String>> _messages = [];
  String? _sessionId;
  bool _isLoadingSession = true;
  bool _isTyping = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    try {
      setState(() {
        _isLoadingSession = true;
        _errorMsg = null;
      });
      final sid = await _aiRepository.createSession();
      setState(() {
        _sessionId = sid;
        _isLoadingSession = false;
      });
      _loadHistory();
    } catch (e) {
      setState(() {
        _isLoadingSession = false;
        _errorMsg = "AI Assistant is currently unavailable. Please try again.";
      });
    }
  }

  Future<void> _loadHistory() async {
    if (_sessionId == null) return;
    try {
      final history = await _aiRepository.getHistory(_sessionId!);
      if (history.isNotEmpty) {
        setState(() {
          _messages.clear();
          for (var msg in history) {
            _messages.add({
              'role': msg['role'] == 'user' ? 'user' : 'bot',
              'text': msg['content']!,
              'predicted_fault': '',
              'estimated_cost': '',
              'repair_time': '',
              'safety_advice': '',
              'confidence': '',
              'timestamp': DateTime.now().toLocal().toString(),
            });
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      // Quietly ignore history errors
    }
  }

  Future<void> _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty || _sessionId == null || _isTyping) return;

    _controller.clear();
    setState(() {
      _messages.add({
        'role': 'user',
        'text': userMessage,
        'timestamp': DateTime.now().toLocal().toString(),
      });
      _isTyping = true;
      _errorMsg = null;
    });
    _scrollToBottom();

    try {
      final chatRes = await _aiRepository.sendChatMessage(userMessage, _sessionId!);
      final botResponse = chatRes['response'] as String;
      final diagnosticDetails = chatRes['diagnostic_details'] as Map<String, dynamic>?;

      setState(() {
        _messages.add({
          'role': 'bot',
          'text': botResponse,
          'predicted_fault': (diagnosticDetails?['predicted_fault'] as String?) ?? "",
          'estimated_cost': (diagnosticDetails?['estimated_cost']?.toString()) ?? "",
          'repair_time': (diagnosticDetails?['repair_time'] as String?) ?? "",
          'safety_advice': (diagnosticDetails?['safety_advice'] as String?) ?? "",
          'confidence': (diagnosticDetails?['confidence']?.toString()) ?? "",
          'timestamp': DateTime.now().toLocal().toString(),
        });
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'role': 'bot',
          'text': "I'm sorry, I couldn't reach the diagnostic server. Please check your internet connection and try again.",
          'timestamp': DateTime.now().toLocal().toString(),
        });
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleQuickAction(String prompt) {
    _controller.text = prompt;
    _sendMessage();
  }

  void _handleBookMechanic(String fault) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Booking workshop request dispatched for: $fault"),
        backgroundColor: AppColors.brandBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatTime(String? timestampStr) {
    if (timestampStr == null) return "";
    try {
      final dt = DateTime.parse(timestampStr);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (_) {
      return "";
    }
  }

  // ── Welcome Screen ───────────────────────────────────────────────
  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          _buildGreeting(),
          const SizedBox(height: 28),
          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Space Grotesk',
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'What do you need help with?',
            style: TextStyle(fontSize: 13, color: context.textTertiary),
          ),
          const SizedBox(height: 12),
          _buildQuickActionsGrid(),
          const SizedBox(height: 28),
          // Recent Conversations
          _buildRecentConversations(),
          const SizedBox(height: 28),
          // Suggested Questions
          Text(
            'Suggested Questions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Space Grotesk',
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSuggestedQuestions(),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting!',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Mecha AI',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Space Grotesk',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Your intelligent vehicle assistant. Ask me about dashboard warnings, diagnostics, repairs, or parts.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final quickActions = [
      {'title': 'Vehicle Diagnosis', 'subtitle': 'AI-powered diagnostics', 'icon': Icons.build_circle_rounded, 'prompt': "My vehicle has a problem, help me diagnose it."},
      {'title': 'Battery Health Analysis', 'subtitle': 'Battery health analysis', 'icon': Icons.battery_charging_full_rounded, 'prompt': "My vehicle battery is not holding charge."},
      {'title': 'Engine Sound Analysis', 'subtitle': 'Unusual sounds analysis', 'icon': Icons.volume_up_rounded, 'prompt': "I hear unusual noises from the engine."},
      {'title': 'Brake Inspection', 'subtitle': 'Brake inspection help', 'icon': Icons.stop_circle_rounded, 'prompt': "My brakes are making squeaking noise."},
      {'title': 'Fuel Consumption Analysis', 'subtitle': 'Mileage optimization', 'icon': Icons.local_gas_station_rounded, 'prompt': "How can I improve my vehicle fuel efficiency?"},
      {'title': 'Service Reminder', 'subtitle': 'Maintenance schedule', 'icon': Icons.calendar_today_rounded, 'prompt': "When should I get my vehicle serviced next?"},
    ];

    return Column(
      children: quickActions.map((action) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: QuickActionCard(
            title: action['title'] as String,
            subtitle: action['subtitle'] as String,
            icon: action['icon'] as IconData,
            onTap: () => _handleQuickAction(action['prompt'] as String),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentConversations() {
    final recentItems = [
      "Engine overheating",
      "Low mileage",
      "Brake vibration",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Conversations',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...recentItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: () => _handleQuickAction(item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.border, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 18, color: context.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: context.textTertiary),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSuggestedQuestions() {
    final suggestions = [
      "What does engine fault code P0115 mean?",
      "When should I change my synthetic engine oil?",
      "My bike won't start and makes a clicking sound.",
      "The engine overheating light is glowing red.",
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((q) {
        return GestureDetector(
          onTap: () => _handleQuickAction(q),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.brandOrange),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    q,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Error banner
          if (_isLoadingSession)
            const LinearProgressIndicator(color: AppColors.brandOrange, minHeight: 2)
          else if (_errorMsg != null)
            _buildErrorBanner(),
          // Messages
          Expanded(
            child: _messages.isEmpty && !_isLoadingSession
                ? _buildWelcomeScreen()
                : _buildChatList(),
          ),
          // Input
          ChatInput(
            controller: _controller,
            enabled: _sessionId != null && !_isLoadingSession,
            hintText: _sessionId == null ? 'Connecting to AI assistant...' : 'Ask Mecha AI anything...',
            onSend: _sendMessage,
            onAttach: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File attachments coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            onVoice: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Voice input coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            onSubmitted: (_) => _sendMessage(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: context.bgSecondary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mecha AI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Space Grotesk',
                  color: context.textPrimary,
                ),
              ),
              Text(
                'Vehicle Expert',
                style: TextStyle(
                  fontSize: 11,
                  color: context.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_messages.isNotEmpty)
          IconButton(
            onPressed: () {
              setState(() => _messages.clear());
              _initSession();
            },
            icon: Icon(Icons.refresh_rounded, color: context.textSecondary, size: 22),
            tooltip: 'New Chat',
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return GestureDetector(
      onTap: _initSession,
      child: Container(
        color: AppColors.errorLight,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              _errorMsg!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.refresh_rounded, size: 16, color: AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator
        if (index == _messages.length && _isTyping) {
          return const ThinkingIndicator();
        }

        final message = _messages[index];
        final isUser = message['role'] == 'user';
        final hasDiag = message['predicted_fault'] != null && message['predicted_fault']!.isNotEmpty;

        return _AnimatedMessageBubble(
          isUser: isUser,
          child: ChatBubble(
            text: message['text']!,
            isUser: isUser,
            timestamp: _formatTime(message['timestamp']),
            bottomContent: hasDiag
                ? DiagnosisCard(
                    fault: message['predicted_fault']!,
                    confidence: message['confidence'],
                    estimatedCost: message['estimated_cost'],
                    repairTime: message['repair_time'],
                    safetyAdvice: message['safety_advice'],
                    onRequestMechanic: () => _handleBookMechanic(message['predicted_fault']!),
                    onOrderParts: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Parts ordering from AI coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onDownloadReport: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report download coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onShareReport: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share report coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  )
                : null,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ── Custom Markdown Renderer ────────────────────────────────────────
class CustomMarkdown extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const CustomMarkdown({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final children = <Widget>[];
    final baseStyle = style ?? TextStyle(fontSize: 14.5, color: context.textPrimary, height: 1.45);

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        children.add(const SizedBox(height: 8));
        continue;
      }

      if (line.startsWith('### ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            line.substring(4),
            style: baseStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
        ));
      } else if (line.startsWith('## ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            line.substring(3),
            style: baseStyle.copyWith(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
        ));
      } else if (line.startsWith('# ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Text(
            line.substring(2),
            style: baseStyle.copyWith(fontSize: 19, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        final content = line.substring(2);
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 8),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.brandOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(child: _parseInlineBold(content, baseStyle)),
            ],
          ),
        ));
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final match = RegExp(r'^(\d+)\.\s(.*)').firstMatch(line);
        if (match != null) {
          final numStr = match.group(1)!;
          final content = match.group(2)!;
          children.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$numStr.",
                  style: baseStyle.copyWith(fontWeight: FontWeight.bold, color: AppColors.brandOrange),
                ),
                const SizedBox(width: 8),
                Expanded(child: _parseInlineBold(content, baseStyle)),
              ],
            ),
          ));
        }
      } else {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _parseInlineBold(line, baseStyle),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _parseInlineBold(String text, TextStyle baseStyle) {
    final parts = text.split('**');
    if (parts.length == 1) return Text(text, style: baseStyle);

    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(TextSpan(
        text: parts[i],
        style: baseStyle.copyWith(
          fontWeight: isBold ? FontWeight.bold : baseStyle.fontWeight,
          color: isBold ? baseStyle.color : baseStyle.color,
        ),
      ));
    }
    return RichText(text: TextSpan(children: spans, style: baseStyle));
  }
}

// ── Expandable Assistant Message Card ───────────────────────────────
class AssistantMessageCard extends StatefulWidget {
  final String text;
  final Widget? bottomContent;
  const AssistantMessageCard({super.key, required this.text, this.bottomContent});

  @override
  State<AssistantMessageCard> createState() => _AssistantMessageCardState();
}

class _AssistantMessageCardState extends State<AssistantMessageCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final textLength = widget.text.length;
    final isLong = textLength > 280;
    final displayedText = (_isExpanded || !isLong)
        ? widget.text
        : "${widget.text.substring(0, 260)}...";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderSoft, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomMarkdown(
            text: displayedText,
            style: TextStyle(fontSize: 14, color: context.textPrimary, height: 1.5),
          ),
          if (isLong) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? 'Show Less' : 'Show More',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandOrange,
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.brandOrange,
                  ),
                ],
              ),
            ),
          ],
          if (widget.bottomContent != null) widget.bottomContent!,
        ],
      ),
    );
  }
}

// ── Animated Message Bubble ─────────────────────────────────────────
class _AnimatedMessageBubble extends StatefulWidget {
  final Widget child;
  final bool isUser;
  const _AnimatedMessageBubble({required this.child, required this.isUser});

  @override
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _offsetAnim = Tween<Offset>(
      begin: Offset(0.0, widget.isUser ? 0.1 : 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: SlideTransition(
        position: _offsetAnim,
        child: widget.child,
      ),
    );
  }
}
