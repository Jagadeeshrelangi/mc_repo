import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

class PriceSummaryCard extends StatelessWidget {
  final double subtotal;
  final double? deliveryFee;
  final double? discount;
  final double? tax;
  final double? couponDiscount;
  final String? couponCode;
  final String? deliveryEta;
  final bool showCheckout;

  const PriceSummaryCard({
    super.key,
    required this.subtotal,
    this.deliveryFee,
    this.discount,
    this.tax,
    this.couponDiscount,
    this.couponCode,
    this.deliveryEta,
    this.showCheckout = true,
  });

  double get _total =>
      subtotal +
      (deliveryFee ?? 0) -
      (discount ?? 0) -
      (couponDiscount ?? 0) +
      (tax ?? 0);

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
            'Price Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Space Grotesk',
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildRow(context, 'Subtotal', '₹${subtotal.toStringAsFixed(0)}'),
          if (deliveryFee != null)
            _buildRow(context, 'Delivery', deliveryFee == 0 ? 'FREE' : '₹${deliveryFee!.toStringAsFixed(0)}',
                valueColor: deliveryFee == 0 ? AppColors.success : null),
          if (discount != null && discount! > 0)
            _buildRow(context, 'Discount', '-₹${discount!.toStringAsFixed(0)}', valueColor: AppColors.success),
          if (couponDiscount != null && couponDiscount! > 0)
            _buildRow(context, 'Coupon ($couponCode)', '-₹${couponDiscount!.toStringAsFixed(0)}', valueColor: AppColors.success),
          if (tax != null)
            _buildRow(context, 'GST (18%)', '₹${tax!.toStringAsFixed(0)}'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: context.borderSoft),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              Text(
                '₹${_total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandOrange,
                  fontFamily: 'Space Grotesk',
                ),
              ),
            ],
          ),
          if (deliveryEta != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    'Delivery by $deliveryEta',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: context.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
