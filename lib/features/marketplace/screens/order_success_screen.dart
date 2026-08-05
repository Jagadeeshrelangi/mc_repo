import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/features/marketplace/utils/currency_formatter.dart';
import 'package:mecha_connect/features/marketplace/navigation.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Confirmation shown after a successful checkout. Reads the last placed
/// order's ids / total / address / payment from the provider.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final ids = provider.lastOrderIds;
    final total = provider.lastOrderTotal;
    final address = provider.checkoutAddress;
    final payment = provider.checkoutPayment;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 52, color: AppColors.successGreen),
              ),
              const SizedBox(height: 20),
              Text(
                'Order Placed!',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: AppResponsive.scaleFont(context, 24),
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your parts are on the way. A confirmation SMS has been sent to your phone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: context.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ids.isNotEmpty)
                      Text(
                        'Order ID: ${ids.first}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                    if (ids.length > 1)
                      Text(
                        '+${ids.length - 1} more',
                        style: TextStyle(
                            fontSize: 12, color: context.textTertiary),
                      ),
                    const SizedBox(height: 10),
                    _row(context, 'Total paid', formatINR(total)),
                    if (address != null) _row(context, 'Deliver to', address),
                    if (payment != null) _row(context, 'Payment', payment),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => openSearch(context),
                  child: const Text('Continue Shopping'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context)
                    .popUntil((route) => route.isFirst),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: context.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
