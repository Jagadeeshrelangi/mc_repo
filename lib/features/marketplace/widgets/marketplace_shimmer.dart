import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';

/// Animated shimmer that tints its child. Composes the marketplace skeleton so
/// the loading experience matches the brand (no external shimmer dependency).
class MarketplaceShimmer extends StatefulWidget {
  final Widget child;

  const MarketplaceShimmer({super.key, required this.child});

  @override
  State<MarketplaceShimmer> createState() => _MarketplaceShimmerState();
}

class _MarketplaceShimmerState extends State<MarketplaceShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkSurface : AppColors.grey100;
    final highlight = isDark ? AppColors.darkBorderLight : AppColors.white;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final slide = _controller.value * 2 - 1;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(slide - 1, 0),
            end: Alignment(slide + 1, 0),
            colors: [base, highlight, base],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = AppSpacing.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Full-page skeleton shown while the marketplace catalog loads.
class MarketplaceLoadingSkeleton extends StatelessWidget {
  const MarketplaceLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = AppResponsive.horizontalPadding(context);
    return MarketplaceShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
        children: const [
          ShimmerBox(height: 48),
          SizedBox(height: AppSpacing.lg),
          ShimmerBox(height: 150, radius: AppSpacing.radiusXl),
          SizedBox(height: AppSpacing.xl),
          ShimmerBox(height: 84),
          SizedBox(height: AppSpacing.xl),
          ShimmerBox(height: 180),
          SizedBox(height: AppSpacing.xl),
          ShimmerBox(height: 180),
        ],
      ),
    );
  }
}
