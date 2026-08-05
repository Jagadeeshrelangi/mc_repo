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
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: ConstrainedContent(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppResponsive.horizontalPadding(context)),
            child: Column(
              children: [
                SizedBox(height: AppSpacing.xxxl),
                _buildCompletedIcon(context),
                SizedBox(height: AppSpacing.lg),
                Text('Service Completed!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary)),
                SizedBox(height: AppSpacing.xs),
                Text('${booking.mechanic.name} has completed the service', style: TextStyle(fontSize: 14, color: context.textTertiary)),
                SizedBox(height: AppSpacing.xxxl),
                _buildInvoice(context),
                SizedBox(height: AppSpacing.xl),
                _buildPaymentStatus(context),
                SizedBox(height: AppSpacing.xl),
                PrimaryActionButton(
                  label: 'Download Invoice',
                  icon: Icons.download_rounded,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice download coming in Sprint 2!'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
                SizedBox(height: AppSpacing.md),
                PrimaryActionButton(
                  label: 'Rate Service',
                  backgroundColor: context.cardBg,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => RatingReviewScreen(
                        mechanic: booking.mechanic,
                      ),
                    ));
                  },
                ),
                SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedIcon(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.successLight,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: const Icon(Icons.check_circle_rounded, size: 48, color: AppColors.success),
    );
  }

  Widget _buildInvoice(BuildContext context) {
    final total = booking.estimatedCost;
    final gst = total * 0.18;
    return InvoiceCard(
      items: [
        InvoiceItem(label: booking.service.name, amount: booking.service.price),
        InvoiceItem(label: 'Platform Fee', amount: 0),
        InvoiceItem(label: 'GST (18%)', amount: gst),
      ],
      total: total,
      paymentStatus: 'Paid',
      paymentMethod: 'Cash',
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
                Text('Payment Successful', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.successDark)),
                Text('Amount: ₹${booking.estimatedCost.toStringAsFixed(0)} • Cash', style: TextStyle(fontSize: 13, color: AppColors.successDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
