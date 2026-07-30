import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_helpers.dart';

class ThinkingIndicator extends StatefulWidget {
  final String? message;

  const ThinkingIndicator({super.key, this.message});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnim;
  int _stepIndex = 0;

  final List<String> _steps = [
    'Thinking',
    'Analyzing vehicle data',
    'Searching knowledge base',
    'Comparing similar issues',
    'Generating repair plan',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _startStepRotation();
  }

  void _startStepRotation() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _stepIndex = (_stepIndex + 1) % _steps.length;
        });
        _startStepRotation();
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
    final isDark = context.isDark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.brandOrange.withValues(alpha: 0.12)
                : AppColors.brandOrangeLight.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.brandOrange.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing AI icon
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brandOrange.withValues(alpha: _pulseAnim.value),
                          AppColors.brandOrangeDark.withValues(alpha: _pulseAnim.value),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              // Step text with fade transition
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  widget.message ?? _steps[_stepIndex],
                  key: ValueKey(_stepIndex),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandOrange,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bouncing dots
              _buildBouncingDots(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBouncingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.25;
            final value = ((_controller.value - delay) % 1.0);
            final opacity = (value < 0.5) ? (value * 2.0) : (2.0 - value * 2.0);
            return Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: AppColors.brandOrange.withValues(alpha: opacity.clamp(0.3, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
