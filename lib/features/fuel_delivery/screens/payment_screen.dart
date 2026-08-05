import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fuel_provider.dart';
import '../widgets/widgets.dart';
import 'order_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'UPI';
  bool _isProcessing = false;

  static const List<(String, IconData, String)> _methods = [
    ('UPI', Icons.payments_rounded, 'Google Pay, PhonePe, Paytm'),
    ('Credit/Debit Card', Icons.credit_card_rounded, 'Visa, Mastercard, RuPay'),
    ('Net Banking', Icons.account_balance_rounded, 'All major banks'),
    ('Cash on Delivery', Icons.money_rounded, 'Pay when delivered'),
    ('Wallet', Icons.account_balance_wallet_rounded, 'Mecha Wallet'),
  ];

  Future<void> _processPayment() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final provider = context.read<FuelProvider>();
    final order = provider.activeOrder;
    if (order == null) {
      setState(() => _isProcessing = false);
      return;
    }

    provider.setPaymentMethod(_selectedMethod);
    await Future.delayed(const Duration(seconds: 2));

    final accepted = await provider.acceptOrder();

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (accepted && provider.activeOrder != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrderConfirmationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Payment failed. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<FuelProvider>();
    final order = provider.activeOrder;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: const Center(child: Text('No active order')),
      );
    }

    final estimate = order.priceEstimate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount to Pay',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary.withValues(
                        alpha: 0.85,
                      ),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${estimate.grandTotal.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${order.fuelType.name} • ${order.quantity.toInt()}L • ${order.id}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary.withValues(
                        alpha: 0.85,
                      ),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Payment Method',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._methods.map(
              (m) => PaymentMethodTile(
                icon: m.$2,
                title: m.$1,
                subtitle: m.$3,
                isSelected: _selectedMethod == m.$1,
                onTap: () => setState(() => _selectedMethod = m.$1),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${estimate.grandTotal.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FuelActionButton(
                label:
                    _isProcessing
                        ? 'Processing...'
                        : 'Pay ₹${estimate.grandTotal.toStringAsFixed(0)}',
                icon: Icons.lock_rounded,
                onTap: _processPayment,
                isLoading: _isProcessing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
