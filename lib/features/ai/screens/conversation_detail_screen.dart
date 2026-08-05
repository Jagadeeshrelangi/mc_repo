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

/// Read-only transcript of a saved conversation with copy, rename, pin,
/// delete and a "continue chatting" CTA.
class ConversationDetailScreen extends StatefulWidget {
  final String conversationId;

  const ConversationDetailScreen({super.key, required this.conversationId});

  @override
  State<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _opened) return;
      _opened = true;
      final provider = context.read<AiProvider>();
      if (provider.currentConversationId != widget.conversationId) {
        provider.openConversation(widget.conversationId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiProvider>();

    final conversation = provider.currentConversation;
    if (conversation == null || conversation.id != widget.conversationId) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conversation')),
        body: AiEmptyState(
          icon: Icons.delete_outline_rounded,
          title: 'Conversation deleted',
          message: 'This conversation is no longer available.',
          actionLabel: 'Back to history',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final messages = conversation.messages;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conversation.title),
            Text(
              '${messages.length} messages • ${_formatDate(conversation.updatedAt)}',
              style: AppTypography.caption.copyWith(
                color: context.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: conversation.isPinned ? 'Unpin' : 'Pin to top',
            onPressed: () => provider.togglePin(widget.conversationId),
            icon: Icon(
              conversation.isPinned
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Rename',
            onPressed: () => _promptRename(context, provider, conversation),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, provider),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                messages.isEmpty
                    ? AiEmptyState(
                      icon: Icons.forum_rounded,
                      title: 'Empty conversation',
                      message: 'This conversation has no messages yet.',
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.base,
                        AppSpacing.base,
                        AppSpacing.base,
                        AppSpacing.base,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return MessageBubble(
                          message: message,
                          onCopy: () => _copyMessage(context, message),
                          onAction: (button) => openAiAction(context, button),
                        );
                      },
                    ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.bgSecondary,
                border: Border(
                  top: BorderSide(color: context.border, width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      () =>
                          openAiChat(context, conversationId: conversation.id),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text('Continue conversation'),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyMessage(BuildContext context, ChatMessage message) async {
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

  Future<void> _promptRename(
    BuildContext context,
    AiProvider provider,
    Conversation conversation,
  ) async {
    final controller = TextEditingController(text: conversation.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rename conversation'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 60,
              decoration: const InputDecoration(hintText: 'Conversation title'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed:
                    () => Navigator.of(context).pop(controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    controller.dispose();
    if (newTitle != null && newTitle.isNotEmpty) {
      await provider.renameConversation(conversation.id, newTitle);
    }
  }

  Future<void> _confirmDelete(BuildContext context, AiProvider provider) async {
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
      await provider.deleteConversation(widget.conversationId);
    }
  }

  String _formatDate(DateTime time) {
    return '${time.day}/${time.month}/${time.year}';
  }
}
