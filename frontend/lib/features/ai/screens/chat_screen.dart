import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/ai/models/models.dart';
import 'package:mecha_connect/features/ai/navigation.dart';
import 'package:mecha_connect/features/ai/providers/ai_provider.dart';
import 'package:mecha_connect/features/ai/widgets/widgets.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// Full chat surface: message thread, typing indicator, inline retry,
/// regenerate, copy and a premium composer. Supports opening an existing
/// conversation or starting fresh with an optional auto-sent [initialPrompt].
class ChatScreen extends StatefulWidget {
  final String? conversationId;
  final String? initialPrompt;

  const ChatScreen({super.key, this.conversationId, this.initialPrompt});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _promptDispatched = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AiProvider>();
      if (widget.conversationId != null) {
        provider.openConversation(widget.conversationId!);
      } else {
        provider.newConversation();
      }
      _maybeSendInitialPrompt(provider);
    });
  }

  void _maybeSendInitialPrompt(AiProvider provider) {
    if (_promptDispatched) return;
    final prompt = widget.initialPrompt;
    if (prompt == null || prompt.trim().isEmpty) return;
    _promptDispatched = true;
    if (provider.messages.isEmpty) {
      provider.sendMessage(prompt);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      final maxExtent = position.maxScrollExtent;
      final nearBottom = position.pixels >= maxExtent - 160;
      if (nearBottom || _lastMessageCount <= 2) {
        _scrollController.animateTo(
          maxExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
      _lastMessageCount = provider.messages.length;
    });
  }

  AiProvider get provider => context.read<AiProvider>();

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AiProvider>();

    final messages = aiProvider.messages;
    final isEmpty = messages.isEmpty && !aiProvider.isSending;

    if (messages.length != _lastMessageCount) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mecha AI'),
            Text(
              aiProvider.isTyping ? 'Typing…' : 'Online',
              style: AppTypography.caption.copyWith(
                color:
                    aiProvider.isTyping
                        ? AppColors.brandOrange
                        : AppColors.success,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New chat',
            onPressed: () {
              _controller.clear();
              aiProvider.newConversation();
            },
            icon: const Icon(Icons.add_comment_rounded),
          ),
          if (aiProvider.hasActiveChat)
            IconButton(
              tooltip: 'Delete conversation',
              onPressed: () => _confirmDeleteCurrent(context, aiProvider),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                isEmpty
                    ? _buildWelcome(context, aiProvider)
                    : _buildThread(context, aiProvider, messages),
          ),
          _buildComposer(context, aiProvider),
        ],
      ),
    );
  }

  Widget _buildWelcome(BuildContext context, AiProvider aiProvider) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 34,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'How can I help?',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMd.copyWith(color: context.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ask about repairs, parts, fuel or maintenance — tap a question to '
          'start.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySm.copyWith(color: context.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'TRY ASKING',
          style: AppTypography.overline.copyWith(color: context.textTertiary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final suggestion in AiProvider.suggestions.take(4))
              SuggestionChip(
                label: suggestion.text,
                onTap: () => aiProvider.sendMessage(suggestion.text),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildThread(
    BuildContext context,
    AiProvider aiProvider,
    List<ChatMessage> messages,
  ) {
    final showRegenerate =
        messages.isNotEmpty && !aiProvider.isSending && !messages.last.isUser;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.base,
        AppSpacing.base,
        AppSpacing.base,
      ),
      itemCount: messages.length + (aiProvider.isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return const TypingIndicator();
        }
        final message = messages[index];
        final isLast = index == messages.length - 1;
        return _AnimatedMessage(
          key: ValueKey(message.id),
          child: MessageBubble(
            message: message,
            showRegenerate: isLast && showRegenerate,
            onRegenerate: () => aiProvider.regenerateLast(),
            onCopy: () => _copyMessage(message),
            onAction: (button) => openAiAction(context, button),
          ),
        );
      },
    );
  }

  Future<void> _copyMessage(ChatMessage message) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: message.content));
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Message copied'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
  }

  Widget _buildComposer(BuildContext context, AiProvider aiProvider) {
    final failedText = aiProvider.lastFailedUserText;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          left: AppSpacing.base,
          right: AppSpacing.base,
          top: AppSpacing.xs,
          bottom: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.bgSecondary,
          border: Border(top: BorderSide(color: context.border, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (failedText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'That reply failed. Try again.',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => aiProvider.retryLast(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                    ),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: context.border, width: 1),
                    ),
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(aiProvider),
                      decoration: InputDecoration(
                        hintText: 'Message Mecha AI…',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Semantics(
                  button: true,
                  label: 'Send message',
                  child: Material(
                    color:
                        aiProvider.isSending
                            ? context.textTertiary
                            : context.accent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    child: InkWell(
                      onTap: () => _send(aiProvider),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _send(AiProvider aiProvider) {
    final text = _controller.text;
    if (text.trim().isEmpty || aiProvider.isSending) return;
    aiProvider.sendMessage(text);
    _controller.clear();
  }

  Future<void> _confirmDeleteCurrent(
    BuildContext context,
    AiProvider aiProvider,
  ) async {
    final conversation = aiProvider.currentConversation;
    if (conversation == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete conversation?'),
            content: const Text(
              'This conversation and its messages will be '
              'removed permanently.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await aiProvider.deleteConversation(conversation.id);
      aiProvider.newConversation();
    }
  }
}

class _AnimatedMessage extends StatefulWidget {
  final Widget child;

  const _AnimatedMessage({super.key, required this.child});

  @override
  State<_AnimatedMessage> createState() => _AnimatedMessageState();
}

class _AnimatedMessageState extends State<_AnimatedMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
