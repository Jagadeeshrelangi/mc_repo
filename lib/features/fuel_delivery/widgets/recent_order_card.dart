import 'package:flutter/material.dart';
import '../models/order_status.dart';
import '../models/fuel_order.dart';

class RecentOrderCard extends StatelessWidget {
  final FuelOrder order;
  final VoidCallback onTap;

  const RecentOrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCancelled = order.status == OrderStatus.cancelled;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isCancelled
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.primaryContainer,
          child: Icon(
            order.fuelType.icon,
            size: 20,
            color: isCancelled
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
        ),
        title: Text(
          '${order.fuelType.name} • ${order.quantity.toInt()}L',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${order.vehicle.number} • ${order.status.label}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '₹${order.priceEstimate.grandTotal.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCancelled
                ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                : theme.colorScheme.primary,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
