import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/ai/models/models.dart';
import 'package:mecha_connect/features/ai/navigation.dart';
import 'package:mecha_connect/features/ai/providers/ai_provider.dart';
import 'package:mecha_connect/features/ai/widgets/widgets.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// Full conversation history with search, pin, rename, delete and clear-all.
class ConversationHistoryScreen extends StatefulWidget {
  const ConversationHistoryScreen({super.key});

  @override
  State<ConversationHistoryScreen> createState() =>
      _ConversationHistoryScreenState();
}

class _ConversationHistoryScreenState extends State<ConversationHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AiProvider>();
      if (provider.state == AiScreenState.initial ||
          provider.state == AiScreenState.error) {
        provider.loadHome();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          if (provider.conversations.isNotEmpty)
            IconButton(
              tooltip: 'Clear all conversations',
              onPressed: () => _confirmClearAll(context, provider),
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildSearchBar(context),
            Expanded(child: _buildBody(context, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.sm,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: 'Search conversations…',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon:
              _query.isEmpty
                  ? null
                  : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
          isDense: true,
          filled: true,
          fillColor: context.cardBgAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(color: context.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(color: context.border),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AiProvider provider) {
    switch (provider.state) {
      case AiScreenState.initial:
      case AiScreenState.loading:
        return const AiLoadingState();
      case AiScreenState.error:
        return AiErrorState(
          message: provider.errorMessage ?? 'Unable to load conversations.',
          onRetry: provider.loadHome,
        );
      case AiScreenState.ready:
        return _buildList(context, provider);
    }
  }

  Widget _buildList(BuildContext context, AiProvider provider) {
    final results = provider.searchConversations(_query);

    if (results.isEmpty) {
      return AiEmptyState(
        icon: _query.isEmpty ? Icons.forum_rounded : Icons.search_off_rounded,
        title: _query.isEmpty ? 'No conversations yet' : 'No matches found',
        message:
            _query.isEmpty
                ? 'Start chatting with Mecha AI and your threads will show up here.'
                : 'Nothing matches \'$_query\'. Try a different search.',
        actionLabel: _query.isEmpty ? 'Start chatting' : null,
        onAction: _query.isEmpty ? () => openAiChat(context) : null,
      );
    }

    final pinned = results.where((c) => c.isPinned).toList();
    final others = results.where((c) => !c.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        0,
        AppSpacing.base,
        AppSpacing.xxl,
      ),
      children: [
        if (pinned.isNotEmpty) ...[
          _sectionLabel(context, 'PINNED'),
          for (final conversation in pinned)
            _tile(context, provider, conversation),
          if (others.isNotEmpty) const SizedBox(height: AppSpacing.md),
        ],
        if (others.isNotEmpty) ...[
          _sectionLabel(
            context,
            pinned.isNotEmpty ? 'ALL CONVERSATIONS' : 'RECENT',
          ),
          for (final conversation in others)
            _tile(context, provider, conversation),
        ],
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: AppTypography.overline.copyWith(color: context.textTertiary),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    AiProvider provider,
    Conversation conversation,
  ) {
    return ConversationTile(
      conversation: conversation,
      onTap: () => openAiConversationDetail(context, conversation.id),
      onPinToggle: () => provider.togglePin(conversation.id),
      onRename: provider.renameConversation,
      onDelete: provider.deleteConversation,
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    AiProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear all conversations?'),
            content: const Text(
              'All conversations and their messages will be '
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
                child: const Text('Clear all'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await provider.clearAllConversations();
    }
  }
}
