import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_responsive.dart';

class ReviewStar extends StatelessWidget {
  final int starIndex;
  final int currentRating;
  final ValueChanged<int>? onTap;

  const ReviewStar({
    super.key,
    required this.starIndex,
    required this.currentRating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = starIndex <= currentRating;
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(starIndex) : null,
      child: AnimatedScale(
        scale: isFilled ? 1.0 : 0.9,
        duration: const Duration(milliseconds: 150),
        child: Icon(
          isFilled ? Icons.star_rounded : Icons.star_border_rounded,
          size: AppResponsive.scaleIcon(context, 44),
          color: isFilled ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
        ),
      ),
    );
  }
}
