import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Module-wide loading state: a branded skeleton of the AI home.
class AiLoadingState extends StatelessWidget {
  const AiLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _block(context, height: 120),
        const SizedBox(height: 20),
        _block(context, height: 24, width: 140),
        const SizedBox(height: 12),
        _block(context, height: 56),
        const SizedBox(height: 8),
        _block(context, height: 56),
        const SizedBox(height: 20),
        _block(context, height: 24, width: 180),
        const SizedBox(height: 12),
        _block(context, height: 84),
        const SizedBox(height: 8),
        _block(context, height: 84),
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
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

/// Pulse animation for the skeleton blocks.
class AiLoadingPulse extends StatefulWidget {
  final Widget child;

  const AiLoadingPulse({super.key, required this.child});

  @override
  State<AiLoadingPulse> createState() => _AiLoadingPulseState();
}

class _AiLoadingPulseState extends State<AiLoadingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1, end: 0.45).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// Brand-colored indeterminate loader shown during inline waits.
class AiActivityIndicator extends StatelessWidget {
  final double size;

  const AiActivityIndicator({super.key, this.size = 22});

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
