import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double starSize;
  final bool showCount;

  const RatingWidget({
    super.key,
    required this.rating,
    this.reviewCount,
    this.starSize = 14,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            return Icon(Icons.star_rounded, size: starSize, color: AppColors.warning);
          } else if (index < rating) {
            return Icon(Icons.star_half_rounded, size: starSize, color: AppColors.warning);
          } else {
            return Icon(Icons.star_outline_rounded, size: starSize, color: AppColors.grey300);
          }
        }),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: starSize * 0.85,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          if (reviewCount != null) ...[
            const SizedBox(width: 2),
            Text(
              '($reviewCount)',
              style: TextStyle(
                fontSize: starSize * 0.75,
                color: context.textTertiary,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
