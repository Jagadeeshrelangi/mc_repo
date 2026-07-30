import 'package:flutter/material.dart';
import '../models/fuel_order.dart';

class RecentOrderCard extends StatelessWidget {
  final FuelOrder order;
  final VoidCallback onTap;

  const RecentOrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(order.fuelType.icon, style: const TextStyle(fontSize: 20)),
        ),
        title: Text('${order.fuelType.name} • ${order.quantity.toInt()}L', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${order.vehicleNumber} • ${order.status.label}', style: const TextStyle(fontSize: 12)),
        trailing: Text('₹${order.priceEstimate.grandTotal.toStringAsFixed(0)}', style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        )),
        onTap: onTap,
      ),
    );
  }
}
