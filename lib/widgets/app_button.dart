import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outline, text, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;
  final Widget? child;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 48;
    final effectiveOnPressed = isLoading ? null : onPressed;

    switch (variant) {
      case AppButtonVariant.primary:
        return _buildElevated(effectiveHeight, effectiveOnPressed);
      case AppButtonVariant.secondary:
        return _buildOutlined(effectiveHeight, effectiveOnPressed);
      case AppButtonVariant.outline:
        return _buildOutlined(effectiveHeight, effectiveOnPressed);
      case AppButtonVariant.text:
        return _buildText(effectiveOnPressed);
      case AppButtonVariant.danger:
        return _buildDanger(effectiveHeight, effectiveOnPressed);
    }
  }

  Widget _buildElevated(double h, VoidCallback? onPressed) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandOrange,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.grey200,
          disabledForegroundColor: AppColors.grey400,
          elevation: AppElevation.medium,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: _buildChild(),
      ),
    );
  }

  Widget _buildOutlined(double h, VoidCallback? onPressed) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, h),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          side: const BorderSide(color: AppColors.grey200, width: 1.5),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: _buildChild(),
      ),
    );
  }

  Widget _buildText(VoidCallback? onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: _buildChild(),
    );
  }

  Widget _buildDanger(double h, VoidCallback? onPressed) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.textOnError,
          elevation: AppElevation.medium,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }
    if (child != null) return child!;
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      );
    }
    return Text(label);
  }
}
