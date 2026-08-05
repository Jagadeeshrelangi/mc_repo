import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/marketplace/models/coupon.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Coupon entry field with Apply/Remove state, plus the applied coupon chip.
class CouponField extends StatefulWidget {
  const CouponField({super.key});

  @override
  State<CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<CouponField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final coupon = provider.appliedCoupon;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: coupon == null,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  prefixIcon: const Icon(Icons.confirmation_number_outlined,
                      size: 20),
                  isDense: true,
                  filled: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: context.border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: coupon == null
                      ? () {
                          final code = _controller.text.trim().toUpperCase();
                          if (code.isEmpty) return;
                          final ok = provider.applyCoupon(code);
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invalid coupon "$code"'),
                              ),
                            );
                          }
                        }
                      : () {
                          provider.removeCoupon();
                          _controller.clear();
                        },
                  child: Text(coupon == null ? 'Apply' : 'Remove'),
                ),
              ),
            ),
          ],
        ),
        if (coupon != null) ...[
          const SizedBox(height: 10),
          _AppliedCouponChip(coupon: coupon),
        ],
      ],
    );
  }
}

class _AppliedCouponChip extends StatelessWidget {
  final Coupon coupon;

  const _AppliedCouponChip({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final savingsLabel = switch (coupon.type) {
      CouponType.percent => 'You save up to ${coupon.value.toStringAsFixed(0)}%',
      CouponType.flat =>
        'You save ${coupon.value.toStringAsFixed(0)} off',
      CouponType.freeDelivery => 'Free delivery unlocked',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.brandOrangeSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded, size: 18,
              color: AppColors.brandOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${coupon.code} applied',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandOrange,
                  ),
                ),
                Text(
                  savingsLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (coupon.type == CouponType.freeDelivery)
            const Icon(Icons.local_shipping_rounded,
                size: 18, color: AppColors.brandOrange),
        ],
      ),
    );
  }
}
