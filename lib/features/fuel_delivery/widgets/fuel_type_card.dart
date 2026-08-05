import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
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
    final disabled = fuelType.comingSoon;

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: !disabled,
      label: fuelType.comingSoon
          ? '${fuelType.name}, coming soon'
          : '${fuelType.name}, ₹${fuelType.pricePerLitre.toStringAsFixed(1)} per litre',
      child: GestureDetector(
        onTap: disabled
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${fuelType.name} is coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            : onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: disabled ? 0.5 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  fuelType.icon,
                  size: 28,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                ),
                const SizedBox(height: 6),
                Text(
                  fuelType.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                if (fuelType.comingSoon)
                  Text(
                    'Coming Soon',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  )
                else
                  Text(
                    '₹${fuelType.pricePerLitre.toStringAsFixed(1)}/L',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
