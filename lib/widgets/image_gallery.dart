import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_helpers.dart';

class ImageGallery extends StatelessWidget {
  final List<String> images;
  final int selectedIndex;
  final ValueChanged<int>? onIndexChanged;

  const ImageGallery({
    super.key,
    required this.images,
    this.selectedIndex = 0,
    this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 300,
        color: context.bgTertiary,
        child: const Center(
          child: Icon(Icons.inventory_2_outlined, size: 60, color: AppColors.grey300),
        ),
      );
    }

    return Column(
      children: [
        // Main image
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.bgTertiary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: onIndexChanged,
              itemBuilder: (context, index) {
                return Image.asset(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.inventory_2_outlined, size: 60, color: AppColors.grey300),
                  ),
                );
              },
            ),
          ),
        ),
        // Thumbnails
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == selectedIndex;
                return GestureDetector(
                  onTap: () => onIndexChanged?.call(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.brandOrange : AppColors.grey200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.asset(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.grey300),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        // Page indicator
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (index) {
              final isSelected = index == selectedIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 20 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandOrange : AppColors.grey300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
