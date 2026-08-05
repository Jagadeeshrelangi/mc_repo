import 'package:flutter/material.dart';
import 'package:mecha_connect/features/marketplace/models/cart.dart';
import 'package:mecha_connect/features/marketplace/utils/currency_formatter.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Line-item bill: MRP, subtotal, GST, delivery, coupon savings and the
/// payable total. Reused by Cart and Checkout.
class PriceSummaryCard extends StatelessWidget {
  final PriceSummary summary;
  final int itemCount;

  const PriceSummaryCard({
    super.key,
    required this.summary,
    this.itemCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value,
        {Color? color, FontWeight weight = FontWeight.w400}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color ?? context.textSecondary,
                fontWeight: weight,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: color ?? context.textPrimary,
                fontWeight: weight,
              ),
            ),
          ],
        ),
      );
    }

    final totalSaved = summary.savings + summary.couponDiscount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: [
          if (itemCount > 0)
            row('Items ($itemCount)',
                formatINR(summary.mrpTotal)),
          if (summary.savings > 0)
            row(
              'MRP savings',
              '-${formatINR(summary.savings)}',
              color: AppColors.successGreen,
              weight: FontWeight.w600,
            ),
          row('Subtotal', formatINR(summary.itemsTotal)),
          row('GST (18%)', formatINR(summary.gst)),
          row(
            'Delivery',
            summary.deliveryFee <= 0
                ? 'FREE'
                : formatINR(summary.deliveryFee),
            color: summary.deliveryFee <= 0 ? AppColors.successGreen : null,
            weight: FontWeight.w600,
          ),
          if (summary.couponDiscount > 0)
            row(
              'Coupon savings',
              '-${formatINR(summary.couponDiscount)}',
              color: AppColors.successGreen,
              weight: FontWeight.w600,
            ),
          if (totalSaved > 0)
            row(
              'You save',
              formatINR(totalSaved),
              color: AppColors.successGreen,
              weight: FontWeight.w600,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: context.divider),
          ),
          row(
            'Total',
            formatINR(summary.grandTotal),
            weight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ],
      ),
    );
  }
}
