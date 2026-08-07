import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

class InvoiceItem {
  final String label;
  final double amount;

  const InvoiceItem({required this.label, required this.amount});
}

class InvoiceCard extends StatelessWidget {
  final List<InvoiceItem> items;
  final double total;
  final String? paymentStatus;
  final String? paymentMethod;

  const InvoiceCard({
    super.key,
    required this.items,
    required this.total,
    this.paymentStatus,
    this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.borderSoft),
        boxShadow: context.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: AppResponsive.scaleIcon(context, 20), color: AppColors.brandOrange),
              SizedBox(width: AppSpacing.sm),
              Text('Invoice', style: TextStyle(fontSize: AppResponsive.scaleFont(context, 16), fontWeight: FontWeight.w700, color: context.textPrimary)),
            ],
          ),
          SizedBox(height: AppSpacing.base),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.label, style: TextStyle(fontSize: AppResponsive.scaleFont(context, 13), color: context.textSecondary)),
                Text('₹${item.amount.toStringAsFixed(0)}', style: TextStyle(fontSize: AppResponsive.scaleFont(context, 13), fontWeight: FontWeight.w600, color: context.textPrimary)),
              ],
            ),
          )),
          Divider(height: AppSpacing.lg, color: context.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TextStyle(fontSize: AppResponsive.scaleFont(context, 16), fontWeight: FontWeight.w700, color: context.textPrimary)),
              Text('₹${total.toStringAsFixed(0)}', style: TextStyle(fontSize: AppResponsive.scaleFont(context, 18), fontWeight: FontWeight.w700, color: AppColors.brandOrange)),
            ],
          ),
          if (paymentStatus != null) ...[
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: paymentStatus == 'Paid' ? AppColors.successLight : AppColors.warningLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    paymentStatus == 'Paid' ? Icons.check_circle_rounded : Icons.pending_rounded,
                    size: AppResponsive.scaleIcon(context, 14),
                    color: paymentStatus == 'Paid' ? AppColors.success : AppColors.warning,
                  ),
                  SizedBox(width: 4),
                  Text(
                    paymentStatus!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: paymentStatus == 'Paid' ? AppColors.successDark : AppColors.warningDark,
                    ),
                  ),
                  if (paymentMethod != null) ...[
                    Text(' • $paymentMethod', style: TextStyle(fontSize: 11, color: paymentStatus == 'Paid' ? AppColors.successDark : AppColors.warningDark)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
