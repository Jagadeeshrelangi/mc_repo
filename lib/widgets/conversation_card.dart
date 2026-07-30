import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_helpers.dart';
import 'severity_badge.dart';

class ConversationCard extends StatelessWidget {
  final String title;
  final String lastMessage;
  final String? timestamp;
  final String? severity;
  final bool isPinned;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ConversationCard({
    super.key,
    required this.title,
    required this.lastMessage,
    this.timestamp,
    this.severity,
    this.isPinned = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isPinned ? AppColors.brandOrange.withValues(alpha: 0.3) : context.border,
            width: isPinned ? 1.5 : 1,
          ),
          boxShadow: context.shadowLow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPinned ? AppColors.brandOrangeLight : context.bgTertiary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPinned ? Icons.push_pin_rounded : Icons.chat_bubble_outline_rounded,
                size: 20,
                color: isPinned ? AppColors.brandOrange : context.textTertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (severity != null) ...[
                        const SizedBox(width: 6),
                        SeverityBadge.fromString(severity: severity!, showLabel: false),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timestamp != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          timestamp!,
                          style: TextStyle(fontSize: 10, color: context.textTertiary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 18, color: context.textTertiary),
          ],
        ),
      ),
    );
  }
}
