import 'package:flutter/material.dart';
import '../models/fuel_type.dart';

class FuelTypeCard extends StatelessWidget {
  final FuelType fuelType;
  final bool isSelected;
  final VoidCallback onTap;

  const FuelTypeCard({
    super.key,
    required this.fuelType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(fuelType.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(fuelType.name, style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
            )),
            const SizedBox(height: 2),
            Text('₹${fuelType.pricePerLitre.toStringAsFixed(1)}/L', style: TextStyle(
              fontSize: 11,
              color: isSelected ? theme.colorScheme.onPrimary.withValues(alpha: 0.8) : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            )),
          ],
        ),
      ),
    );
  }
}
