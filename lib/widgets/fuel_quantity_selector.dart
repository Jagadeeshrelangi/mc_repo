import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

class FuelQuantitySelector extends StatelessWidget {
  final String fuelType;
  final double litres;
  final double rupees;
  final double pricePerLitre;
  final ValueChanged<double> onLitresChanged;
  final ValueChanged<double> onRupeesChanged;

  const FuelQuantitySelector({
    super.key,
    required this.fuelType,
    required this.litres,
    required this.rupees,
    required this.pricePerLitre,
    required this.onLitresChanged,
    required this.onRupeesChanged,
  });

  static const List<double> _presets = [2, 5, 10, 20];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset chips
        Row(
          children: [
            ..._presets.map((preset) {
              final isSelected = (litres - preset).abs() < 0.1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    onLitresChanged(preset);
                    onRupeesChanged(preset * pricePerLitre);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brandOrange : context.bgTertiary,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: isSelected ? AppColors.brandOrange : AppColors.grey200,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${preset.toStringAsFixed(0)}L',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : context.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '₹${pricePerLitre.toStringAsFixed(0)}/L',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quantity display
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quantity', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '${litres.toStringAsFixed(1)} L',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.textPrimary, fontFamily: 'Space Grotesk'),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 32,
              color: AppColors.grey200,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '₹${rupees.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.brandOrange, fontFamily: 'Space Grotesk'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.brandOrange,
            inactiveTrackColor: AppColors.grey200,
            thumbColor: AppColors.brandOrange,
            overlayColor: AppColors.brandOrange.withValues(alpha: 0.1),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: litres,
            min: 1,
            max: 30,
            divisions: 29,
            onChanged: (v) {
              onLitresChanged(v);
              onRupeesChanged(v * pricePerLitre);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('1L', style: TextStyle(fontSize: 11, color: AppColors.grey400)),
            const Text('30L', style: TextStyle(fontSize: 11, color: AppColors.grey400)),
          ],
        ),
      ],
    );
  }
}
