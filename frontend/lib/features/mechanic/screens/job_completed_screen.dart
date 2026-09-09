import 'package:flutter/material.dart';
import 'package:mecha_connect/features/mechanic/models/models.dart';
import 'package:mecha_connect/features/mechanic/screens/rating_review_screen.dart';
import 'package:mecha_connect/features/mechanic/widgets/invoice_card.dart';
import 'package:mecha_connect/features/mechanic/widgets/primary_action_button.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

class JobCompletedScreen extends StatelessWidget {
  final Booking booking;

  const JobCompletedScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: context.bgPrimary,
        appBar: AppBar(
          backgroundColor: context.bgSecondary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Job Summary & Invoice',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Space Grotesk',
              color: context.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Back to Home',
              icon: Icon(Icons.home_rounded, color: context.textPrimary),
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ],
        ),
        body: ConstrainedContent(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppResponsive.horizontalPadding(context)),
              child: Column(
                children: [
                  SizedBox(height: AppSpacing.lg),
                  _buildCompletedIcon(context),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Service Completed!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Space Grotesk',
                      color: context.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    '${booking.mechanic.name} has completed the service',
                    style: TextStyle(fontSize: 14, color: context.textTertiary),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  _buildInvoice(context),
                  SizedBox(height: AppSpacing.lg),
                  _buildPaymentStatus(context),
                  SizedBox(height: AppSpacing.xl),
                  PrimaryActionButton(
                    label: 'Rate Service & Technician',
                    icon: Icons.star_rate_rounded,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => RatingReviewScreen(
                            bookingId: booking.bookingId,
                            mechanic: booking.mechanic,
                            serviceName: booking.service.name,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                      icon: const Icon(Icons.home_rounded, size: 20),
                      label: const Text(
                        'Back to Home',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.textPrimary,
                        side: BorderSide(color: context.borderSoft),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedIcon(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.successLight,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.check_circle_rounded, size: 44, color: AppColors.success),
    );
  }

  Widget _buildInvoice(BuildContext context) {
    final total = booking.estimatedCost;
    final basePrice = booking.service.price > 0 ? booking.service.price : (total > 0 ? total : 499.0);
    final gst = basePrice * 0.18;
    return InvoiceCard(
      items: [
        InvoiceItem(label: booking.service.name, amount: basePrice),
        const InvoiceItem(label: 'Platform Booking Fee', amount: 0),
        InvoiceItem(label: 'GST (18% included)', amount: gst),
      ],
      total: total > 0 ? total : basePrice,
      paymentStatus: 'Paid',
      paymentMethod: 'Cash / Digital',
    );
  }

  Widget _buildPaymentStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 24, color: AppColors.success),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Verified',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.successDark,
                  ),
                ),
                Text(
                  'Amount: ₹${booking.estimatedCost.toStringAsFixed(0)} • Reference: ${booking.bookingId}',
                  style: const TextStyle(fontSize: 12, color: AppColors.successDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
