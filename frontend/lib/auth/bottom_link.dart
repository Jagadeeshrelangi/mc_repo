import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';

class BottomLink extends StatelessWidget {
  final String prefix;
  final String linkText;
  final VoidCallback onTap;

  const BottomLink({
    super.key,
    required this.prefix,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prefix,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            ' $linkText',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.brandOrange,
            ),
          ),
        ),
      ],
    );
  }
}
