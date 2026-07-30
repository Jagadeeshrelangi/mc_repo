import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_helpers.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final VoidCallback? onSend;
  final VoidCallback? onAttach;
  final VoidCallback? onVoice;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const ChatInput({
    super.key,
    required this.controller,
    this.hintText = 'Ask Mecha AI anything...',
    this.enabled = true,
    this.onSend,
    this.onAttach,
    this.onVoice,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attach button
            GestureDetector(
              onTap: onAttach,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: context.bgTertiary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add_rounded, size: 20, color: context.textTertiary),
              ),
            ),
            const SizedBox(width: 8),
            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                decoration: BoxDecoration(
                  color: context.bgTertiary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.borderSoft, width: 1),
                ),
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textPrimary,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(color: context.textTertiary, fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Voice button
            GestureDetector(
              onTap: onVoice,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: context.bgTertiary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.mic_rounded, size: 20, color: context.textTertiary),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: enabled ? onSend : null,
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(bottom: 0),
                decoration: BoxDecoration(
                  gradient: enabled
                      ? const LinearGradient(
                          colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
                        )
                      : null,
                  color: enabled ? null : (isDark ? AppColors.darkSurface : AppColors.grey200),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.send_rounded, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
