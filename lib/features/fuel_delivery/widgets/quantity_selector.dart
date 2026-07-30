import 'package:flutter/material.dart';
import '../constants/fuel_constants.dart';

class QuantitySelector extends StatelessWidget {
  final double quantity;
  final ValueChanged<double> onChanged;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quantity', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            _presetChip(context, '1 L', 1),
            const SizedBox(width: 8),
            _presetChip(context, '2 L', 2),
            const SizedBox(width: 8),
            _presetChip(context, '3 L', 3),
            const SizedBox(width: 8),
            _presetChip(context, '5 L', 5),
            const SizedBox(width: 8),
            _presetChip(context, '10 L', 10),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton.filled(
              onPressed: quantity > FuelConstants.minLitres ? () => onChanged(quantity - 1) : null,
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primaryContainer),
            ),
            const SizedBox(width: 16),
            Text('${quantity.toInt()} L', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            IconButton.filled(
              onPressed: quantity < FuelConstants.maxLitres ? () => onChanged(quantity + 1) : null,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primaryContainer),
            ),
          ],
        ),
      ],
    );
  }

  Widget _presetChip(BuildContext context, String label, double value) {
    final isSelected = quantity == value;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
