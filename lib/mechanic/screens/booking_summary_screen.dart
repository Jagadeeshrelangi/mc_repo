import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/mechanic/mock_data.dart';
import 'package:mecha_connect/mechanic/widgets/booking_summary_card.dart';
import 'package:mecha_connect/mechanic/widgets/primary_action_button.dart';
import 'package:mecha_connect/mechanic/screens/booking_confirmation_screen.dart';

class BookingSummaryScreen extends StatelessWidget {
  final MechanicInfo mechanic;
  final MechanicService service;

  const BookingSummaryScreen({
    super.key,
    required this.mechanic,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final total = service.price + (mechanic.isAvailable ? 0 : 100);
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Booking Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary)),
      ),
      body: ConstrainedContent(
        child: SingleChildScrollView(
        padding: EdgeInsets.all(AppResponsive.horizontalPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review your booking', style: TextStyle(fontSize: 14, color: context.textTertiary)),
            SizedBox(height: AppSpacing.lg),
            BookingSummaryCard(label: 'Mechanic', value: mechanic.name, icon: Icons.person_rounded),
            SizedBox(height: AppSpacing.sm),
            BookingSummaryCard(label: 'Vehicle', value: 'Honda Activa 6G • KA 01 AB 1234', icon: Icons.directions_car_rounded),
            SizedBox(height: AppSpacing.sm),
            BookingSummaryCard(label: 'Service', value: '${service.name} • ${service.estimatedMinutes} mins', icon: service.icon),
            SizedBox(height: AppSpacing.sm),
            BookingSummaryCard(label: 'Address', value: '123, Main Road, Surampalem', icon: Icons.location_on_rounded),
            SizedBox(height: AppSpacing.sm),
            BookingSummaryCard(label: 'Estimated Arrival', value: '${mechanic.etaMinutes} minutes', icon: Icons.access_time_rounded),
            SizedBox(height: AppSpacing.lg),
            _buildCostBreakdown(context, service.price, total),
            SizedBox(height: AppSpacing.base),
            _buildCouponSection(context),
            SizedBox(height: AppSpacing.lg),
            _buildTotalRow(context, total),
            SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(AppResponsive.horizontalPadding(context), AppSpacing.base, AppResponsive.horizontalPadding(context), MediaQuery.of(context).padding.bottom + AppSpacing.base),
        child: PrimaryActionButton(
          label: 'Confirm Booking',
          onPressed: () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => BookingConfirmationScreen(
                mechanic: mechanic,
                service: service,
                totalCost: total,
              ),
            ));
          },
        ),
      ),
    );
  }

  Widget _buildCostBreakdown(BuildContext context, double servicePrice, double total) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.borderSoft),
      ),
      child: Column(
        children: [
          _buildCostRow(context, 'Service Charge', '₹${servicePrice.toStringAsFixed(0)}'),
          if (servicePrice > 0) ...[
            SizedBox(height: AppSpacing.sm),
            _buildCostRow(context, 'Platform Fee', 'Free'),
          ],
          SizedBox(height: AppSpacing.sm),
          _buildCostRow(context, 'GST (18%)', '₹${(servicePrice * 0.18).toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _buildCostRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: context.textSecondary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
      ],
    );
  }

  Widget _buildCouponSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.borderSoft, width: 1, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          Icon(Icons.discount_rounded, size: 20, color: AppColors.brandOrange),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('Apply Coupon', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
          ),
          Text('No coupon applied', style: TextStyle(fontSize: 12, color: context.textTertiary)),
          SizedBox(width: AppSpacing.xs),
          Icon(Icons.chevron_right_rounded, size: 20, color: context.textTertiary),
        ],
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, double total) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.brandOrangeSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary)),
          Text('₹${total.toStringAsFixed(0)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.brandOrange)),
        ],
      ),
    );
  }
}
