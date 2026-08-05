import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:provider/provider.dart';
import '../providers/fuel_provider.dart';
import 'live_tracking_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = context.watch<FuelProvider>().activeOrder;

    if (order == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: TextButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Back to Home'),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.check_circle_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Order Placed!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your fuel delivery order has been confirmed',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.textTertiary,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.border, width: 1),
                ),
                child: Column(
                  children: [
                    _detailRow(context, 'Order ID', order.id),
                    const SizedBox(height: 10),
                    _detailRow(
                      context,
                      'Fuel',
                      '${order.fuelType.name} • ${order.quantity.toInt()} L',
                    ),
                    const SizedBox(height: 10),
                    _detailRow(context, 'Vehicle', order.vehicle.summary),
                    const SizedBox(height: 10),
                    _detailRow(
                      context,
                      'Station',
                      order.station?.name ?? '—',
                    ),
                    const SizedBox(height: 10),
                    _detailRow(context, 'Delivery', order.deliveryLocation.address),
                    const SizedBox(height: 10),
                    _detailRow(context, 'Payment', order.paymentMethod),
                    const Divider(height: 24),
                    _detailRow(
                      context,
                      'Total',
                      '₹${order.priceEstimate.grandTotal.toStringAsFixed(2)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
                    );
                  },
                  icon: const Icon(Icons.near_me_rounded),
                  label: const Text(
                    'Track Delivery',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: context.textTertiary),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? theme.colorScheme.primary : context.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
