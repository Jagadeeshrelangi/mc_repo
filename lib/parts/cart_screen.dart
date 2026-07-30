import 'package:flutter/material.dart';
import 'package:mecha_connect/parts/order_data.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/price_summary_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_helpers.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selecttems;
  final Function(Map<String, dynamic>) onRemove;

  const CartScreen({
    super.key,
    required this.selecttems,
    required this.onRemove,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _selectedPaymentMethod = '';
  final String _deliveryAddress = '123 MG Road, Bangalore, Karnataka';

  double get _subtotal {
    double total = 0;
    for (var item in widget.selecttems) {
      total += (item['price'] as int) * (item['quantity'] as int);
    }
    return total;
  }

  double get _deliveryFee => _subtotal > 999 ? 0 : 49;
  double get _tax => _subtotal * 0.18;
  double get _total => _subtotal + _deliveryFee + _tax;

  void _removeItem(Map<String, dynamic> item) {
    widget.onRemove(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['name']} removed from cart'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _placeOrder() {
    ordersList.addAll(widget.selecttems.map((item) => Map<String, dynamic>.from(item)));
    _showOrderConfirmation();
  }

  void _showOrderConfirmation() {
    final isDark = context.isDark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.grey300,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Order Placed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Space Grotesk',
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order of ₹${_total.toStringAsFixed(0)} has been placed successfully.',
              style: TextStyle(fontSize: 14, color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Estimated delivery: 3-5 business days',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => widget.selecttems.clear());
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue Shopping',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Space Grotesk'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Cart (${widget.selecttems.length})',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Space Grotesk',
            color: context.textPrimary,
          ),
        ),
        actions: [
          if (widget.selecttems.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() => widget.selecttems.clear());
              },
              child: const Text(
                'Clear All',
                style: TextStyle(fontSize: 13, color: AppColors.error),
              ),
            ),
        ],
      ),
      body: widget.selecttems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.selecttems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = widget.selecttems[index];
                      return CartItemCard(
                        name: item['name'],
                        brand: item['brand'] ?? 'Generic',
                        imagePath: item['image'],
                        price: (item['price'] as int).toDouble(),
                        quantity: item['quantity'] as int,
                        onIncrement: () => setState(() => item['quantity']++),
                        onDecrement: () => setState(() {
                          if (item['quantity'] > 1) {
                            item['quantity']--;
                          } else {
                            _removeItem(item);
                          }
                        }),
                        onRemove: () => _removeItem(item),
                      );
                    },
                  ),
                ),
                // Bottom section
                _buildBottomSection(),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    final isDark = context.isDark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.bgTertiary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_cart_outlined, size: 48, color: isDark ? AppColors.darkTextTertiary : AppColors.grey300),
            ),
            const SizedBox(height: 20),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Space Grotesk',
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Looks like you haven\'t added any parts yet',
              style: TextStyle(fontSize: 14, color: context.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Start Shopping',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price summary
          PriceSummaryCard(
            subtotal: _subtotal,
            deliveryFee: _deliveryFee,
            tax: _tax,
            deliveryEta: '3-5 business days',
          ),
          const SizedBox(height: 16),
          // Address
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.bgTertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.border, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandOrangeLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: AppColors.brandOrange, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deliver to',
                        style: TextStyle(fontSize: 11, color: context.textTertiary),
                      ),
                      Text(
                        _deliveryAddress,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkTextTertiary : AppColors.grey400),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Payment methods
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.bgTertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Method',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPaymentOption('UPI', Icons.account_balance_wallet_rounded),
                    const SizedBox(width: 8),
                    _buildPaymentOption('Card', Icons.credit_card_rounded),
                    const SizedBox(width: 8),
                    _buildPaymentOption('COD', Icons.money_rounded),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Checkout button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.selecttems.isNotEmpty ? _placeOrder : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandOrange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.grey300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Place Order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Space Grotesk',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${_total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Space Grotesk',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == label;
    final isDark = context.isDark;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandOrangeLight : context.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.brandOrange : context.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.brandOrange : (isDark ? AppColors.darkTextSecondary : AppColors.grey500),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.brandOrange : context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
