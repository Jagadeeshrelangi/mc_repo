import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_helpers.dart';

class TimelineTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? time;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;

  const TimelineTile({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.time,
    this.isCompleted = false,
    this.isCurrent = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success
                        : isCurrent
                            ? AppColors.brandOrange
                            : AppColors.grey200,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: AppColors.brandOrange.withValues(alpha: 0.3), width: 3)
                        : null,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : icon,
                    size: 16,
                    color: isCompleted || isCurrent ? Colors.white : AppColors.grey400,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? AppColors.success : AppColors.grey200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCompleted || isCurrent
                          ? context.textPrimary
                          : context.textTertiary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textTertiary,
                      ),
                    ),
                  ],
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      time!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isCompleted ? AppColors.success : context.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
