import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SosButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;

  const SosButton({super.key, required this.onPressed, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.error, Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency, size: 22, color: AppColors.white),
            SizedBox(height: 1),
            Text(
              'SOS',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SosFab extends StatelessWidget {
  final VoidCallback onPressed;

  const SosFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.error,
      foregroundColor: AppColors.white,
      elevation: 4,
      child: const Icon(Icons.emergency, size: 28),
    );
  }
}
