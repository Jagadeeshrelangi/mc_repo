import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/profile/providers/profile_provider.dart';
import 'package:mecha_connect/features/profile/widgets/profile_loading.dart';
import 'package:mecha_connect/features/profile/widgets/profile_empty.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';
import 'package:mecha_connect/widgets/order_card.dart';

/// Unified order history across every service type (parts, mechanic, fuel, AI
/// reports). Reads the SAME store the Orders tab uses — no second list.
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Order History',
          style: AppTypography.titleLg.copyWith(color: context.textPrimary),
        ),
      ),
      body: provider.state == ProfileScreenState.initial ||
              provider.state == ProfileScreenState.loading
          ? const ProfileLoadingState()
          : provider.orders.isEmpty
              ? const ProfileEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders yet',
                  message: 'Orders for parts, mechanic, fuel and AI reports '
                      'will appear here.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.xl),
                  children: [
                    for (final order in provider.orders)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: OrderCard(
                          title: order['name']?.toString() ?? 'Order',
                          subtitle:
                              'Qty: ${order['quantity']} · ${order['brand'] ?? 'Generic'}',
                          status: order['status']?.toString(),
                          date: order['date']?.toString(),
                          total: ((order['price'] as num?) ?? 0).toDouble() *
                              ((order['quantity'] as num?) ?? 1).toDouble(),
                          type: _orderType(order['type']?.toString()),
                        ),
                      ),
                  ],
                ),
    );
  }

  OrderType _orderType(String? value) {
    switch (value) {
      case 'mechanic':
        return OrderType.mechanic;
      case 'fuel':
        return OrderType.fuel;
      case 'aiReport':
        return OrderType.aiReport;
      default:
        return OrderType.parts;
    }
  }
}
