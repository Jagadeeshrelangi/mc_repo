import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/marketplace/models/order_models.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/features/marketplace/screens/order_success_screen.dart';
import 'package:mecha_connect/features/marketplace/widgets/address_sheet.dart';
import 'package:mecha_connect/features/marketplace/widgets/price_summary_card.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Checkout flow: delivery address, payment method and the final price
/// summary. Places the order through [MarketplaceProvider.placeOrder].
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _paymentMethods = [
    ('UPI', Icons.qr_code_rounded),
    ('Card', Icons.credit_card_rounded),
    ('Net Banking', Icons.account_balance_outlined),
    ('Wallet', Icons.account_balance_wallet_outlined),
    ('Cash on Delivery', Icons.payments_outlined),
  ];

  CheckoutAddress? _address;
  String _payment = 'UPI';
  bool _placing = false;

  Future<void> _placeOrder(MarketplaceProvider provider) async {
    if (_address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a delivery address first.')),
      );
      return;
    }
    setState(() => _placing = true);
    final ok = await provider.placeOrder(
      address: _address!,
      paymentMethod: _payment,
    );
    if (!mounted) return;
    setState(() => _placing = false);
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Order failed. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    final cart = provider.cart;
    final summary = provider.priceSummary;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body:
          cart.isEmpty
              ? Center(
                child: Text(
                  'Your cart is empty.',
                  style: TextStyle(color: context.textTertiary),
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(AppSpacing.base),
                children: [
                  _sectionTitle(context, '1. Delivery Address'),
                  const SizedBox(height: 8),
                  _AddressCard(
                    address: _address,
                    onTap: () async {
                      final result = await showAddressSheet(context);
                      if (result != null && mounted) {
                        setState(() => _address = result);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(context, '2. Payment Method'),
                  const SizedBox(height: 8),
                  _PaymentCard(
                    selected: _payment,
                    onSelected: (p) => setState(() => _payment = p),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(context, '3. Order Summary'),
                  const SizedBox(height: 8),
                  PriceSummaryCard(
                    summary: summary,
                    itemCount: provider.cartCount,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
      bottomNavigationBar:
          cart.isEmpty
              ? null
              : SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    10,
                    AppSpacing.base,
                    10,
                  ),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    border: Border(top: BorderSide(color: context.border)),
                  ),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _placing ? null : () => _placeOrder(provider),
                      child:
                          _placing
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                'Place Order  •  ₹${summary.grandTotal.round()}',
                              ),
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: AppResponsive.scaleFont(context, 15),
        fontWeight: FontWeight.w700,
        color: context.textPrimary,
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final CheckoutAddress? address;
  final VoidCallback onTap;

  const _AddressCard({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final filled = address != null;
    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: filled ? AppColors.brandOrange : context.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                filled
                    ? Icons.location_on_rounded
                    : Icons.add_location_alt_outlined,
                color: filled ? AppColors.brandOrange : context.textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    filled
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${address!.name}  •  ${address!.phone}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              address!.fullAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        )
                        : Text(
                          'Add delivery address',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textTertiary,
                          ),
                        ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.brandOrange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _PaymentCard({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (method, icon) in _CheckoutScreenState._paymentMethods)
            RadioListTile<String>(
              value: method,
              groupValue: selected,
              onChanged: (v) {
                if (v != null) onSelected(v);
              },
              activeColor: AppColors.brandOrange,
              dense: true,
              secondary: Icon(icon, size: 20, color: AppColors.brandOrange),
              title: Text(method, style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
