import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Skeleton loading placeholder shown while profile data streams in.
class ProfileLoadingState extends StatelessWidget {
  const ProfileLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _block(context, height: 132),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _block(context, height: 84)),
            const SizedBox(width: 10),
            Expanded(child: _block(context, height: 84)),
            const SizedBox(width: 10),
            Expanded(child: _block(context, height: 84)),
            const SizedBox(width: 10),
            Expanded(child: _block(context, height: 84)),
          ],
        ),
        const SizedBox(height: 20),
        _block(context, height: 24, width: 140),
        const SizedBox(height: 10),
        _block(context, height: 72),
        const SizedBox(height: 10),
        _block(context, height: 72),
        const SizedBox(height: 20),
        _block(context, height: 24, width: 120),
        const SizedBox(height: 10),
        _block(context, height: 88),
        const SizedBox(height: 10),
        _block(context, height: 88),
      ],
    );
  }

  Widget _block(BuildContext context, {required double height, double? width}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: context.cardBgAlt,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}

/// Brand-orange activity indicator used across Profile surfaces.
class ProfileActivityIndicator extends StatelessWidget {
  final double size;

  const ProfileActivityIndicator({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2.5,
        color: AppColors.brandOrange,
      ),
    );
  }
}
