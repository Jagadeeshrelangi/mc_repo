import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import '../constants/fuel_constants.dart';

class QuantitySelector extends StatelessWidget {
  final double quantity;
  final ValueChanged<double> onChanged;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
  });

  bool get _isCustom => !FuelConstants.presetLitres.contains(quantity);

  void _showCustomDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _CustomQuantityDialog(
        initial: quantity.clamp(FuelConstants.minLitres, FuelConstants.maxLitres),
        onConfirm: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ...FuelConstants.presetLitres.map(
              (v) => _presetChip(context, '${v.toInt()} L', v),
            ),
            _presetChip(
              context,
              'Custom',
              null,
              isCustomSelected: _isCustom,
              onTap: () => _showCustomDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton.filled(
              onPressed: quantity > FuelConstants.minLitres
                  ? () => onChanged(quantity - 1)
                  : null,
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
              tooltip: 'Decrease quantity',
            ),
            const SizedBox(width: 16),
            Text(
              '${quantity.toInt()} L',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            IconButton.filled(
              onPressed: quantity < FuelConstants.maxLitres
                  ? () => onChanged(quantity + 1)
                  : null,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
              tooltip: 'Increase quantity',
            ),
          ],
        ),
      ],
    );
  }

  Widget _presetChip(
    BuildContext context,
    String label,
    double? value, {
    bool isCustomSelected = false,
    VoidCallback? onTap,
  }) {
    final isSelected = isCustomSelected || (value != null && quantity == value);
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Select quantity $label',
      child: GestureDetector(
        onTap: onTap ?? (value == null ? null : () => onChanged(value)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: isSelected
                ? null
                : Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomQuantityDialog extends StatefulWidget {
  final double initial;
  final ValueChanged<double> onConfirm;

  const _CustomQuantityDialog({
    required this.initial,
    required this.onConfirm,
  });

  @override
  State<_CustomQuantityDialog> createState() => _CustomQuantityDialogState();
}

class _CustomQuantityDialogState extends State<_CustomQuantityDialog> {
  late double _value = widget.initial.roundToDouble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Custom Quantity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_value.toInt()} L',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.brandOrange,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _value,
            min: FuelConstants.minLitres,
            max: FuelConstants.maxLitres,
            divisions: (FuelConstants.maxLitres - FuelConstants.minLitres).toInt(),
            label: '${_value.toInt()} L',
            onChanged: (v) => setState(() => _value = v.roundToDouble()),
          ),
          Text(
            '${FuelConstants.minLitres.toInt()}–${FuelConstants.maxLitres.toInt()} litres',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onConfirm(_value);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
