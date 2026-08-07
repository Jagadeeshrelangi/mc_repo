import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mecha_connect/features/ai/models/models.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// A single chat message bubble with premium styling.
///
/// Supports: user/assistant alignment, timestamps, rich block rendering,
/// action buttons, copy (long-press or icon) and an optional regenerate action
/// for the last assistant reply.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showRegenerate;
  final Future<void> Function() onCopy;
  final VoidCallback? onRegenerate;
  final void Function(AiActionButton button) onAction;

  const MessageBubble({
    super.key,
    required this.message,
    required this.onCopy,
    required this.onAction,
    this.showRegenerate = false,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: message.content));
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Message copied'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 1),
              ),
            );
        },
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser) _buildAssistantHeader(context),
            Container(
              margin: EdgeInsets.only(
                left: isUser ? 48 : 0,
                right: isUser ? 0 : 48,
                top: isUser ? 2 : 4,
                bottom: 2,
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.82,
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.md,
                AppSpacing.base,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isUser ? context.accent : context.cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSpacing.radiusLg),
                  topRight: const Radius.circular(AppSpacing.radiusLg),
                  bottomLeft: Radius.circular(isUser ? AppSpacing.radiusLg : 4),
                  bottomRight: Radius.circular(
                    isUser ? 4 : AppSpacing.radiusLg,
                  ),
                ),
                border:
                    isUser ? null : Border.all(color: context.border, width: 1),
                boxShadow: context.shadowLow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    _buildCopyIcon(context, alignEnd: true)
                  else ...[
                    AiMarkdownText(
                      text: message.content,
                      color: context.textPrimary,
                    ),
                    if (message.response != null &&
                        message.response!.blocks.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _AiBlocks(blocks: message.response!.blocks),
                    ],
                  ],
                  if (isUser)
                    AiMarkdownText(
                      text: message.content,
                      color: AppColors.white,
                    ),
                  if (message.response != null &&
                      message.response!.actions.isNotEmpty &&
                      !isUser) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ActionButtons(
                      actions: message.response!.actions,
                      onAction: onAction,
                    ),
                  ],
                ],
              ),
            ),
            _buildTimestampRow(context),
            if (showRegenerate && onRegenerate != null)
              _buildRegenerate(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Mecha AI',
            style: AppTypography.labelMd.copyWith(
              color: context.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          _buildCopyIcon(context, alignEnd: false),
        ],
      ),
    );
  }

  Widget _buildCopyIcon(BuildContext context, {required bool alignEnd}) {
    return Semantics(
      button: true,
      label: 'Copy message',
      child: Tooltip(
        message: 'Copy message',
        child: GestureDetector(
          onTap: onCopy,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.copy_rounded,
              size: 13,
              color:
                  alignEnd
                      ? AppColors.white.withValues(alpha: 0.8)
                      : context.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimestampRow(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 0 : 4,
        right: isUser ? 4 : 0,
        top: 2,
        bottom: 4,
      ),
      child: Text(
        _formatTime(message.timestamp),
        style: AppTypography.caption.copyWith(color: context.textTertiary),
      ),
    );
  }

  Widget _buildRegenerate(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: GestureDetector(
        onTap: onRegenerate,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 14, color: context.accent),
            const SizedBox(width: 5),
            Text(
              'Regenerate',
              style: AppTypography.labelMd.copyWith(color: context.accent),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ── Rich blocks ─────────────────────────────────────────────────────────

class _AiBlocks extends StatelessWidget {
  final List<AiBlock> blocks;

  const _AiBlocks({required this.blocks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks) ...[
          const SizedBox(height: AppSpacing.sm),
          _AiBlockCard(block: block),
        ],
      ],
    );
  }
}

class _AiBlockCard extends StatelessWidget {
  final AiBlock block;

  const _AiBlockCard({required this.block});

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case AiBlockType.warning:
        return _tintedCard(
          context,
          icon: Icons.warning_amber_rounded,
          accent: AppColors.warning,
          child: _BlockText(text: block.text ?? ''),
        );
      case AiBlockType.recommendation:
        return _tintedCard(
          context,
          icon: Icons.lightbulb_rounded,
          accent: AppColors.brandBlue,
          child: _BlockText(text: block.text ?? ''),
        );
      case AiBlockType.checklist:
        return _tintedCard(
          context,
          icon: Icons.checklist_rounded,
          accent: AppColors.success,
          child: _BlockList(
            items: block.items,
            leadingBuilder:
                (index) => const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
          ),
        );
      case AiBlockType.costEstimate:
        return _tintedCard(
          context,
          icon: Icons.currency_rupee_rounded,
          accent: AppColors.brandOrange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BlockList(items: block.items),
              if (block.note != null) ...[
                const SizedBox(height: 6),
                Text(
                  block.note!,
                  style: AppTypography.titleSm.copyWith(
                    color: context.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        );
      case AiBlockType.bulletList:
        return _tintedCard(
          context,
          icon: Icons.format_list_bulleted_rounded,
          accent: context.accent,
          child: _BlockList(
            items: block.items,
            leadingBuilder:
                (index) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: BoxDecoration(
                    color: context.accent,
                    shape: BoxShape.circle,
                  ),
                ),
          ),
        );
      case AiBlockType.text:
        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _BlockText(text: block.text ?? ''),
        );
    }
  }

  Widget _tintedCard(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (block.title != null) ...[
            Row(
              children: [
                Icon(icon, size: 16, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    block.title!,
                    style: AppTypography.titleSm.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}

class _BlockText extends StatelessWidget {
  final String text;

  const _BlockText({required this.text});

  @override
  Widget build(BuildContext context) {
    return AiMarkdownText(
      text: text,
      color: context.textPrimary,
      style: AppTypography.bodySm,
    );
  }
}

class _BlockList extends StatelessWidget {
  final List<String> items;
  final Widget Function(int index)? leadingBuilder;

  const _BlockList({required this.items, this.leadingBuilder});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leadingBuilder?.call(i) ??
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '•  ',
                      style: AppTypography.bodySm.copyWith(
                        color: context.textPrimary,
                      ),
                    ),
                  ),
              const SizedBox(width: 8),
              Expanded(
                child: AiMarkdownText(
                  text: items[i],
                  color: context.textPrimary,
                  style: AppTypography.bodySm,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Action buttons ──────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final List<AiActionButton> actions;
  final void Function(AiActionButton button) onAction;

  const _ActionButtons({required this.actions, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final action in actions)
          OutlinedButton(
            onPressed: () => onAction(action),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.accent,
              side: BorderSide(color: context.accent.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: 8,
              ),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
            ),
            child: Text(action.label, style: AppTypography.labelMd),
          ),
      ],
    );
  }
}

// ── Lightweight markdown renderer ───────────────────────────────────────

/// Minimal markdown renderer used by AI messages:
/// code fences, inline code, **bold**, bullet/numbered lists and links.
/// Unknown markdown is passed through as plain text — it never throws.
class AiMarkdownText extends StatelessWidget {
  final String text;
  final Color color;
  final TextStyle? style;

  const AiMarkdownText({
    super.key,
    required this.text,
    required this.color,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final base = (style ?? AppTypography.bodyMd).copyWith(color: color);
    final isDark = context.isDark;
    final codeStyle = base.copyWith(
      fontFamily: 'monospace',
      fontSize: base.fontSize! - 1,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.grey100,
    );

    return RichText(text: _buildSpans(text, base, codeStyle, context));
  }

  TextSpan _buildSpans(
    String text,
    TextStyle base,
    TextStyle code,
    BuildContext context,
  ) {
    final spans = <InlineSpan>[];
    final lines = text.split('\n');
    var inCodeBlock = false;
    final codeLines = <String>[];

    void flushCodeBlock() {
      spans.add(
        WidgetSpan(child: _CodeBlock(lines: codeLines, base: base, code: code)),
      );
      spans.add(const TextSpan(text: '\n'));
      codeLines.clear();
    }

    for (final rawLine in lines) {
      final line = rawLine;
      if (line.trimLeft().startsWith('```')) {
        if (inCodeBlock) {
          flushCodeBlock();
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
          codeLines.clear();
        }
        continue;
      }
      if (inCodeBlock) {
        codeLines.add(line);
        continue;
      }
      spans.add(_parseInline(line, base, code, context));
      spans.add(const TextSpan(text: '\n'));
    }
    if (inCodeBlock && codeLines.isNotEmpty) {
      flushCodeBlock();
    }

    return TextSpan(style: base, children: spans);
  }

  TextSpan _parseInline(
    String line,
    TextStyle base,
    TextStyle code,
    BuildContext context,
  ) {
    final bulletMatch = RegExp(r'^\s*([-*•])\s+(.*)$').firstMatch(line);
    if (bulletMatch != null) {
      return TextSpan(
        children: [
          const TextSpan(text: '•  '),
          TextSpan(
            children: _inlineSpans(bulletMatch.group(2)!, base, code, context),
          ),
        ],
      );
    }
    final numberMatch = RegExp(r'^\s*(\d+)\.\s+(.*)$').firstMatch(line);
    if (numberMatch != null) {
      return TextSpan(
        children: [
          TextSpan(text: '${numberMatch.group(1)}.  ', style: base),
          TextSpan(
            children: _inlineSpans(numberMatch.group(2)!, base, code, context),
          ),
        ],
      );
    }
    return TextSpan(children: _inlineSpans(line, base, code, context));
  }

  List<InlineSpan> _inlineSpans(
    String line,
    TextStyle base,
    TextStyle code,
    BuildContext context,
  ) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'(\*\*(.+?)\*\*|`(.+?)`|\[(.+?)\]\((.+?)\))');
    var lastEnd = 0;

    for (final match in pattern.allMatches(line)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: line.substring(lastEnd, match.start)));
      }
      final bold = match.group(2);
      final inlineCode = match.group(3);
      final linkText = match.group(4);
      final linkUrl = match.group(5);
      if (bold != null) {
        spans.add(
          TextSpan(
            text: bold,
            style: base.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (inlineCode != null) {
        spans.add(TextSpan(text: inlineCode, style: code));
      } else if (linkText != null && linkUrl != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: linkUrl));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
              },
              child: Text(
                linkText,
                style: base.copyWith(
                  color: context.accent,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        );
      }
      lastEnd = match.end;
    }
    if (lastEnd < line.length) {
      spans.add(TextSpan(text: line.substring(lastEnd)));
    }
    return spans;
  }
}

class _CodeBlock extends StatelessWidget {
  final List<String> lines;
  final TextStyle base;
  final TextStyle code;

  const _CodeBlock({
    required this.lines,
    required this.base,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: SelectableText(
        lines.join('\n'),
        style: code.copyWith(
          color: isDark ? AppColors.darkTextSecondary : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }
}
