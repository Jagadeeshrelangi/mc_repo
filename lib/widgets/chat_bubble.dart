import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_helpers.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? timestamp;
  final Widget? bottomContent;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.timestamp,
    this.bottomContent,
    this.isExpanded = false,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAssistantLabel(context),
          Container(
            margin: EdgeInsets.only(
              left: isUser ? 60 : 12,
              right: isUser ? 12 : 60,
              top: 4,
              bottom: 4,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isUser ? AppColors.brandOrange : context.cardBg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: isUser ? null : Border.all(color: context.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isUser ? Colors.white : context.textPrimary,
                  ),
                ),
                if (bottomContent != null) ...[
                  const SizedBox(height: 12),
                  bottomContent!,
                ],
                if (isExpanded && text.length > 280 && onToggleExpand != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onToggleExpand,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Show Less',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isUser ? Colors.white70 : AppColors.brandBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (timestamp != null)
            Padding(
              padding: EdgeInsets.only(
                left: isUser ? 0 : 16,
                right: isUser ? 16 : 0,
                bottom: 8,
                top: 2,
              ),
              child: Text(
                timestamp!,
                style: TextStyle(fontSize: 10, color: context.textTertiary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAssistantLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.psychology_rounded, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(
            'Mecha AI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.brandOrange,
            ),
          ),
        ],
      ),
    );
  }
}
