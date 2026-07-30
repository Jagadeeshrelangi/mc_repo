import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_helpers.dart';

class InvoiceCard extends StatelessWidget {
  final String orderId;
  final String date;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double? tax;
  final double? discount;
  final double total;
  final String? paymentMethod;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;

  const InvoiceCard({
    super.key,
    required this.orderId,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.total,
    this.tax,
    this.discount,
    this.paymentMethod,
    this.onDownload,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.borderSoft, width: 1),
        boxShadow: context.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandBlueLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_rounded, size: 18, color: AppColors.brandBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice #$orderId',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(fontSize: 11, color: context.textTertiary),
                    ),
                  ],
                ),
              ),
              if (paymentMethod != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    paymentMethod!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Items
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${item['name'] ?? ''} ${item['quantity'] != null ? 'x${item['quantity']}' : ''}',
                    style: TextStyle(fontSize: 13, color: context.textSecondary),
                  ),
                ),
                Text(
                  '₹${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: context.borderSoft),
          ),
          // Summary
          _buildRow(context, 'Subtotal', '₹${subtotal.toStringAsFixed(0)}'),
          if (discount != null && discount! > 0)
            _buildRow(context, 'Discount', '-₹${discount!.toStringAsFixed(0)}', color: AppColors.success),
          if (tax != null)
            _buildRow(context, 'GST', '₹${tax!.toStringAsFixed(0)}'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: context.borderSoft),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary),
              ),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandOrange,
                  fontFamily: 'Space Grotesk',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Actions
          Row(
            children: [
              Expanded(
                child: _buildAction(context, 'Download', Icons.download_rounded, onDownload),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAction(context, 'Share', Icons.share_rounded, onShare),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: context.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, String label, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: context.bgTertiary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderSoft, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: context.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
