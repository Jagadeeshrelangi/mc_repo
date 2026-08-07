import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';

/// A row of five rating stars (full / half / empty) with the numeric value.
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showValue;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 14,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rated ${rating.toStringAsFixed(1)} out of 5',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 5; i++) _buildStar(i),
            if (showValue) ...[
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: size * 0.85,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandOrange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStar(int index) {
    final value = rating - index;
    final icon = value >= 0.75
        ? Icons.star_rounded
        : value >= 0.25
            ? Icons.star_half_rounded
            : Icons.star_border_rounded;
    return Icon(icon, size: size, color: AppColors.warning);
  }
}
