import 'package:flutter/material.dart';

class FuelActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isLoading;

  const FuelActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isPrimary ? theme.colorScheme.primary : theme.colorScheme.secondary;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
            : Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
