import 'package:flutter/material.dart';
import 'package:mecha_connect/features/mechanic/models/models.dart';
import 'package:mecha_connect/features/mechanic/screens/live_tracking_screen.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Booking booking;

  const BookingConfirmationScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: ConstrainedContent(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppResponsive.horizontalPadding(context)),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildSuccessIcon(context),
                SizedBox(height: AppSpacing.xl),
                Text('Booking Confirmed!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary)),
                SizedBox(height: AppSpacing.sm),
                Text('Your mechanic is on the way', style: TextStyle(fontSize: 15, color: context.textTertiary)),
                SizedBox(height: AppSpacing.xxxl),
                _buildDetailsCard(context, booking),
                SizedBox(height: AppSpacing.xxxl),
                _buildActions(context),
                SizedBox(height: AppSpacing.base),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.successLight,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: const Icon(Icons.check_circle_rounded, size: 56, color: AppColors.success),
    );
  }

  Widget _buildDetailsCard(BuildContext context, Booking booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.borderSoft),
        boxShadow: context.shadowLow,
      ),
      child: Column(
        children: [
          Text('Booking ID', style: TextStyle(fontSize: 12, color: context.textTertiary)),
          SizedBox(height: 4),
          Text(booking.bookingId, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
          SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem(context, 'Mechanic', booking.mechanic.name),
              _buildDetailItem(context, 'Service', booking.service.name),
            ],
          ),
          SizedBox(height: AppSpacing.base),
          _buildDetailItem(context, 'Estimated Arrival', '${booking.mechanic.etaMinutes} minutes'),
          SizedBox(height: AppSpacing.base),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                SizedBox(width: 6),
                Text('Mechanic Assigned', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.successDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.textTertiary)),
        SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ${booking.mechanic.name}...'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Call', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => LiveTrackingScreen(bookingId: booking.bookingId),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.cardBg,
                    foregroundColor: context.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: context.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.near_me_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Track Live', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: Text('Back to Home', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textTertiary)),
        ),
      ],
    );
  }
}
