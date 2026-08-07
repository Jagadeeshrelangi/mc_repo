import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import '../models/order_status.dart';

/// Animated 7-state delivery timeline.
///
/// Renders [requested, accepted, fuelPacked, partnerAssigned, enRoute,
/// arrived, delivered] with completed steps in accent color and the current
/// step highlighted.
class TrackingTimeline extends StatelessWidget {
  final OrderStatus status;

  const TrackingTimeline({super.key, required this.status});

  static const List<OrderStatus> _steps = [
    OrderStatus.requested,
    OrderStatus.accepted,
    OrderStatus.fuelPacked,
    OrderStatus.partnerAssigned,
    OrderStatus.enRoute,
    OrderStatus.arrived,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = status == OrderStatus.cancelled ? 0 : status.stepIndex;
    final done = status == OrderStatus.cancelled ? 0 : current;

    return Semantics(
      label: 'Delivery status: ${status.label}',
      child: Column(
        children: List.generate(_steps.length, (i) {
          final step = _steps[i];
          final isDone = i <= done;
          final isCurrent = i == current && !status.isTerminal;
          final isLast = i == _steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppColors.success : theme.colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.brandOrange
                            : isDone
                                ? AppColors.success
                                : theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: isCurrent ? 3 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? Icon(Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                    ),
                  ),
                  if (!isLast)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      width: 3,
                      height: 28,
                      color: i < done
                          ? AppColors.success
                          : theme.colorScheme.outline.withValues(alpha: 0.15),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: isCurrent ? 4 : 6, bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          color: isCurrent
                              ? theme.colorScheme.primary
                              : isDone
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Current status',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: AppColors.brandOrange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
