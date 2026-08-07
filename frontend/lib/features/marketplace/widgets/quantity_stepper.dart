import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';

/// Compact - / count / + stepper used on cart lines and the product page.
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = maxQuantity > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : Colors.grey.shade400;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Button(
            icon: Icons.remove_rounded,
            onTap:
                enabled && quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 34),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          _Button(
            icon: Icons.add_rounded,
            onTap:
                enabled && quantity < maxQuantity
                    ? () => onChanged(quantity + 1)
                    : null,
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _Button({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label:
          icon == Icons.add_rounded ? 'Increase quantity' : 'Decrease quantity',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Icon(
            icon,
            size: 18,
            color:
                onTap == null
                    ? (isDark ? AppColors.darkTextTertiary : Colors.grey.shade400)
                    : isDark
                    ? Colors.white
                    : AppColors.brandOrange,
          ),
        ),
      ),
    );
  }
}
