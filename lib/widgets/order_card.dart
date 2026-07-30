import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

enum OrderType { mechanic, fuel, parts, aiReport }

class OrderCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? status;
  final String? date;
  final double? total;
  final OrderType type;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  const OrderCard({
    super.key,
    required this.title,
    required this.type,
    this.subtitle,
    this.status,
    this.date,
    this.total,
    this.imageUrl,
    this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: context.border, width: 1),
          boxShadow: context.shadowLow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(_typeIcon, size: 24, color: _typeColor),
                      ),
                    )
                  : Icon(_typeIcon, size: 24, color: _typeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (status != null) ...[
                        const SizedBox(width: 8),
                        _buildStatusChip(status!),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: context.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (date != null) ...[
                        Icon(Icons.schedule_rounded, size: 12, color: context.textTertiary),
                        const SizedBox(width: 3),
                        Text(
                          date!,
                          style: TextStyle(fontSize: 11, color: context.textTertiary),
                        ),
                      ],
                      const Spacer(),
                      if (total != null)
                        Text(
                          '₹${total!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                            fontFamily: 'Space Grotesk',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.grey300, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String s) {
    final color = s.toLowerCase() == 'completed'
        ? AppColors.success
        : s.toLowerCase() == 'cancelled'
            ? AppColors.error
            : s.toLowerCase() == 'pending'
                ? AppColors.warning
                : AppColors.brandBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        s.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Color get _typeColor {
    switch (type) {
      case OrderType.mechanic: return AppColors.brandBlue;
      case OrderType.fuel: return AppColors.success;
      case OrderType.parts: return AppColors.brandOrange;
      case OrderType.aiReport: return AppColors.brandBlueDark;
    }
  }

  IconData get _typeIcon {
    switch (type) {
      case OrderType.mechanic: return Icons.build_rounded;
      case OrderType.fuel: return Icons.local_gas_station_rounded;
      case OrderType.parts: return Icons.inventory_2_rounded;
      case OrderType.aiReport: return Icons.psychology_rounded;
    }
  }
}
