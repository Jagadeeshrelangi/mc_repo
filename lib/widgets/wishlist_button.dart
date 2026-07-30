import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class WishlistButton extends StatefulWidget {
  final bool isWishlisted;
  final VoidCallback? onTap;
  final double size;

  const WishlistButton({
    super.key,
    this.isWishlisted = false,
    this.onTap,
    this.size = 40,
  });

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    if (widget.isWishlisted) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(WishlistButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWishlisted && !oldWidget.isWishlisted) {
      _controller.forward(from: 0.0);
    } else if (!widget.isWishlisted && oldWidget.isWishlisted) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.isWishlisted
                ? AppColors.errorLight
                : Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Icon(
            widget.isWishlisted
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: widget.size * 0.45,
            color: widget.isWishlisted ? AppColors.error : AppColors.grey400,
          ),
        ),
      ),
    );
  }
}
