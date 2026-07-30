import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

class TimelineTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;
  final bool isFirst;
  final bool isLast;

  const TimelineTile({
    super.key,
    required this.title,
    this.subtitle = '',
    this.isCompleted = false,
    this.isActive = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppResponsive.scale(context, 40),
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? AppColors.success : context.borderSoft,
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
                Container(
                  width: AppResponsive.scale(context, 24),
                  height: AppResponsive.scale(context, 24),
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.success : (isActive ? AppColors.brandOrange : context.bgTertiary),
                    shape: BoxShape.circle,
                    border: !isCompleted && !isActive ? Border.all(color: context.border) : null,
                  ),
                  child: isCompleted
                      ? Icon(Icons.check_rounded, size: AppResponsive.scaleIcon(context, 14), color: Colors.white)
                      : (isActive ? Icon(Icons.circle_rounded, size: 10, color: Colors.white) : null),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? AppColors.success : context.borderSoft,
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: isFirst ? 0 : 2, bottom: isLast ? 0 : 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppResponsive.scaleFont(context, 14),
                      fontWeight: FontWeight.w600,
                      color: isCompleted || isActive ? context.textPrimary : context.textTertiary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: context.textTertiary),
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
