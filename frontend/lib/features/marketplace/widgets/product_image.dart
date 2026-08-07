import 'package:flutter/material.dart';
import 'package:mecha_connect/features/marketplace/models/product.dart';
import 'package:mecha_connect/theme/app_colors.dart';

/// Renders a product photo with a guaranteed fallback: if the asset is missing
/// or fails to load, a branded icon tile is shown instead — so the UI never
/// breaks on an image error.
class ProductImage extends StatelessWidget {
  final Product product;
  final double? width;
  final double height;
  final BoxFit fit;
  final double radius;

  const ProductImage({
    super.key,
    required this.product,
    this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _iconFallback(),
        ),
      );
    }
    return _iconFallback();
  }

  Widget _iconFallback() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandOrangeSoft, Color(0xFFFCE7DB)],
        ),
      ),
      child: Icon(
        product.icon,
        size: 44,
        color: AppColors.brandOrange,
      ),
    );
  }
}
