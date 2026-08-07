import 'package:flutter/material.dart';
import 'package:mecha_connect/features/mechanic/models/models.dart';
import 'package:mecha_connect/features/mechanic/providers/mechanic_provider.dart';
import 'package:mecha_connect/features/mechanic/screens/booking_confirmation_screen.dart';
import 'package:mecha_connect/features/mechanic/widgets/booking_summary_card.dart';
import 'package:mecha_connect/features/mechanic/widgets/primary_action_button.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:provider/provider.dart';

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
    final provider = context.watch<MechanicProvider>();
    final request = provider.bookingRequest;
    final total = service.price + (mechanic.isAvailable ? 0 : 100);
    final vehicle = request?.vehicleSummary ?? 'Honda Activa 6G';
    final address = request?.address ?? '123, Main Road, Surampalem';
    final registration = request?.registration ?? 'KA 01 AB 1234';

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
              BookingSummaryCard(label: 'Vehicle', value: '$vehicle • $registration', icon: Icons.directions_car_rounded),
              SizedBox(height: AppSpacing.sm),
              BookingSummaryCard(label: 'Service', value: '${service.name} • ${service.estimatedMinutes} mins', icon: service.icon),
              SizedBox(height: AppSpacing.sm),
              BookingSummaryCard(label: 'Address', value: address, icon: Icons.location_on_rounded),
              SizedBox(height: AppSpacing.sm),
              BookingSummaryCard(label: 'Estimated Arrival', value: '${mechanic.etaMinutes} minutes', icon: Icons.access_time_rounded),
              SizedBox(height: AppSpacing.lg),
              _buildCostBreakdown(context, service.price, mechanic.isAvailable),
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
          isLoading: provider.isSubmitting,
          onPressed: provider.isSubmitting
              ? null
              : () async {
                  try {
                    final booking = await context.read<MechanicProvider>().createBooking(
                          mechanic: mechanic,
                          service: service,
                        );
                    if (!context.mounted) return;
                    // Booking is confirmed: clear the stale booking-flow
                    // screens below so Back never reopens a booking screen.
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => BookingConfirmationScreen(booking: booking),
                      ),
                      (route) => route.isFirst,
                    );
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(provider.errorMessage ?? 'Could not create booking.'), behavior: SnackBarBehavior.floating),
                    );
                  }
                },
        ),
      ),
    );
  }

  Widget _buildCostBreakdown(
      BuildContext context, double servicePrice, bool isAvailable) {
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
          if (!isAvailable) ...[
            SizedBox(height: AppSpacing.sm),
            _buildCostRow(context, 'Availability Surcharge', '₹100'),
          ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coupons coming in Sprint 2!'), behavior: SnackBarBehavior.floating),
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
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
        ),
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
