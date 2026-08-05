import 'package:flutter/material.dart';
import 'package:mecha_connect/features/mechanic/models/models.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

class BookingHistoryCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;

  const BookingHistoryCard({super.key, required this.booking, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: context.borderSoft),
            boxShadow: context.shadowLow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.brandOrangeSoft,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(booking.service.icon, size: 22, color: AppColors.brandOrange),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.mechanic.name,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          booking.service.name,
                          style: TextStyle(fontSize: 12, color: context.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(booking.status.icon, size: 14, color: statusColor),
                        SizedBox(width: 4),
                        Text(
                          booking.status.label,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Divider(height: 1, color: context.divider),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.directions_car_rounded, size: 14, color: context.textTertiary),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.vehicle,
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '₹${booking.estimatedCost.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.brandOrange),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                _formatDate(booking.bookingTime),
                style: TextStyle(fontSize: 11, color: context.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.cancelled:
        return AppColors.error;
      case BookingStatus.requested:
      case BookingStatus.accepted:
        return AppColors.warning;
      case BookingStatus.mechanicAssigned:
      case BookingStatus.enRoute:
      case BookingStatus.arrived:
        return AppColors.brandOrange;
    }
  }

  String _formatDate(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
