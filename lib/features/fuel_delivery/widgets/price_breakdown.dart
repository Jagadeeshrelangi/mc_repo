import 'package:flutter/material.dart';
import '../models/price_estimate.dart';

class PriceBreakdown extends StatelessWidget {
  final PriceEstimate estimate;

  const PriceBreakdown({super.key, required this.estimate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Breakdown', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _row('Fuel Cost', '₹${estimate.fuelCost.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _row('Delivery Charge', '₹${estimate.deliveryCharge.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _row('Platform Fee', '₹${estimate.platformFee.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _row('Taxes', '₹${estimate.taxes.toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1),
          ),
          _row('Grand Total', '₹${estimate.grandTotal.toStringAsFixed(2)}', isBold: true),
          const SizedBox(height: 4),
          Text('Est. delivery: ${estimate.etaMinutes} min', style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          )),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w600 : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }
}
