import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

class PriceBreakdownCard extends StatelessWidget {
  final String fuelType;
  final double quantity;
  final double pricePerLitre;
  final double deliveryFee;
  final String? eta;

  const PriceBreakdownCard({
    super.key,
    required this.fuelType,
    required this.quantity,
    required this.pricePerLitre,
    this.deliveryFee = 29,
    this.eta,
  });

  double get _fuelCost => quantity * pricePerLitre;
  double get _taxes => _fuelCost * 0.02;
  double get _total => _fuelCost + deliveryFee + _taxes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.border, width: 1),
        boxShadow: context.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildRow(context, 'Fuel Type', fuelType),
          _buildRow(context, 'Quantity', '${quantity.toStringAsFixed(1)} L'),
          _buildRow(context, 'Fuel Price', '₹${_fuelCost.toStringAsFixed(0)}'),
          _buildRow(context, 'Delivery Fee', '₹${deliveryFee.toStringAsFixed(0)}'),
          _buildRow(context, 'Taxes (2%)', '₹${_taxes.toStringAsFixed(0)}'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: context.borderSoft),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary),
              ),
              Text(
                '₹${_total.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.brandOrange, fontFamily: 'Space Grotesk'),
              ),
            ],
          ),
          if (eta != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated arrival: $eta',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: context.textSecondary)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
        ],
      ),
    );
  }
}
