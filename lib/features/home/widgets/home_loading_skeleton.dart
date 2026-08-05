import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';

class HomeLoadingSkeleton extends StatefulWidget {
  const HomeLoadingSkeleton({super.key});

  @override
  State<HomeLoadingSkeleton> createState() => _HomeLoadingSkeletonState();
}

class _HomeLoadingSkeletonState extends State<HomeLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.4, end: 0.9).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppResponsive.scale(context, 16)),
            _buildHeaderSkeleton(context),
            SizedBox(height: AppResponsive.scale(context, 14)),
            _buildBoxSkeleton(context, height: 76),
            SizedBox(height: AppResponsive.scale(context, 14)),
            _buildBoxSkeleton(context, height: 52),
            SizedBox(height: AppResponsive.scale(context, 16)),
            _buildBoxSkeleton(context, height: 92),
            SizedBox(height: AppResponsive.scale(context, 16)),
            _buildBoxSkeleton(context, height: 190),
            SizedBox(height: AppResponsive.scale(context, 20)),
            _buildBoxSkeleton(context, height: 130),
            SizedBox(height: AppResponsive.scale(context, 24)),
            _buildGridSkeleton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSkeleton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPadding(context),
      ),
      child: Row(
        children: [
          _circleSkeleton(context, radius: 26),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(context, width: 120, height: 12),
                SizedBox(height: AppSpacing.sm),
                _bar(context, width: 160, height: 18),
              ],
            ),
          ),
          _circleSkeleton(context, radius: 23),
        ],
      ),
    );
  }

  Widget _buildGridSkeleton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPadding(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _box(context, height: 88)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: _box(context, height: 88)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: _box(context, height: 88)),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _box(context, height: 88)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: _box(context, height: 88)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: _box(context, height: 88)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoxSkeleton(BuildContext context, {required double height}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPadding(context),
      ),
      child: _box(context, height: height),
    );
  }

  Widget _box(BuildContext context, {required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _skeletonColor(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
    );
  }

  Widget _bar(BuildContext context, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _skeletonColor(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
    );
  }

  Widget _circleSkeleton(BuildContext context, {required double radius}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: _skeletonColor(context),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _skeletonColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkSurface : AppColors.grey200;
  }
}
