import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_helpers.dart';

class TrackingTimeline extends StatelessWidget {
  final int currentStep;

  const TrackingTimeline({super.key, required this.currentStep});

  static const List<_TimelineStep> _steps = [
    _TimelineStep(Icons.assignment_outlined, 'Mechanic Assigned', 'A mechanic has accepted your request'),
    _TimelineStep(Icons.directions_car_filled, 'On The Way', 'Mechanic is heading to your location'),
    _TimelineStep(Icons.location_on_outlined, 'Arrived', 'Mechanic has reached your location'),
    _TimelineStep(Icons.build_circle_outlined, 'Repair Started', 'Work is in progress'),
    _TimelineStep(Icons.check_circle_outline, 'Completed', 'Service completed successfully'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_steps.length, (index) {
        final step = _steps[index];
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;
        final isFuture = index > currentStep;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line + dot
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.success
                          : isCurrent
                              ? AppColors.brandOrange
                              : AppColors.grey200,
                      border: isCurrent
                          ? Border.all(color: AppColors.brandOrange.withValues(alpha: 0.3), width: 4)
                          : null,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_rounded : step.icon,
                      size: 14,
                      color: isCompleted || isCurrent ? Colors.white : AppColors.grey400,
                    ),
                  ),
                  if (index < _steps.length - 1)
                    Container(
                      width: 2,
                      height: 32,
                      color: isCompleted ? AppColors.success : AppColors.grey200,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isFuture ? context.textTertiary : context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isFuture ? context.textTertiary : context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TimelineStep {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TimelineStep(this.icon, this.title, this.subtitle);
}
