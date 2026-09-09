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

class BookingSummaryScreen extends StatefulWidget {
  final MechanicInfo mechanic;
  final MechanicService service;

  const BookingSummaryScreen({
    super.key,
    required this.mechanic,
    required this.service,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  bool _isScheduled = false;
  DateTime? _scheduledDateTime;
  bool _isSubmittingLocal = false;

  Future<void> _pickScheduleTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _isScheduled = true;
      _scheduledDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = monthNames[dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month ${dt.year}, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MechanicProvider>();
    final request = provider.bookingRequest;
    final surcharge = widget.mechanic.isAvailable ? 0.0 : 100.0;
    final total = widget.service.price + surcharge;
    final vehicle = request?.vehicleSummary ?? 'Vehicle Details';
    final address = request?.address ?? 'Customer Service Address';
    final registration = request?.registration ?? 'Registered Vehicle';

    final isBusy = provider.isSubmitting || _isSubmittingLocal;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Booking Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Space Grotesk',
            color: context.textPrimary,
          ),
        ),
      ),
      body: ConstrainedContent(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppResponsive.horizontalPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review your booking details before confirming',
                style: TextStyle(fontSize: 14, color: context.textTertiary),
              ),
              SizedBox(height: AppSpacing.lg),
              BookingSummaryCard(
                label: 'Mechanic',
                value: widget.mechanic.name,
                icon: Icons.person_rounded,
              ),
              SizedBox(height: AppSpacing.sm),
              BookingSummaryCard(
                label: 'Vehicle',
                value: '$vehicle • $registration',
                icon: Icons.directions_car_rounded,
              ),
              SizedBox(height: AppSpacing.sm),
              BookingSummaryCard(
                label: 'Service',
                value: '${widget.service.name} • ${widget.service.estimatedMinutes} mins',
                icon: widget.service.icon,
              ),
              SizedBox(height: AppSpacing.sm),
              BookingSummaryCard(
                label: 'Address',
                value: address,
                icon: Icons.location_on_rounded,
              ),
              SizedBox(height: AppSpacing.sm),
              _buildScheduleCard(context),
              SizedBox(height: AppSpacing.lg),
              _buildCostBreakdown(context, widget.service.price, widget.mechanic.isAvailable),
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
        padding: EdgeInsets.fromLTRB(
          AppResponsive.horizontalPadding(context),
          AppSpacing.base,
          AppResponsive.horizontalPadding(context),
          MediaQuery.of(context).padding.bottom + AppSpacing.base,
        ),
        child: PrimaryActionButton(
          label: isBusy ? 'Creating Booking...' : 'Confirm Booking',
          isLoading: isBusy,
          onPressed: isBusy
              ? null
              : () async {
                  setState(() => _isSubmittingLocal = true);
                  try {
                    final booking = await context.read<MechanicProvider>().createBooking(
                          mechanic: widget.mechanic,
                          service: widget.service,
                          scheduledAt: _isScheduled ? _scheduledDateTime : null,
                        );
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => BookingConfirmationScreen(booking: booking),
                      ),
                      (route) => route.isFirst,
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    final msg = provider.errorMessage ?? 'Could not create booking. Please try again.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _isSubmittingLocal = false);
                    }
                  }
                },
        ),
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.brandOrange),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Timing',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _pickScheduleTime,
                icon: Icon(
                  _isScheduled ? Icons.edit_calendar_rounded : Icons.add_rounded,
                  size: 16,
                  color: AppColors.brandOrange,
                ),
                label: Text(
                  _isScheduled ? 'Change' : 'Schedule',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_isScheduled && _scheduledDateTime != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandOrangeSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Scheduled',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDateTime(_scheduledDateTime!),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Reset to immediate',
                  icon: Icon(Icons.close_rounded, size: 16, color: context.textTertiary),
                  onPressed: () => setState(() {
                    _isScheduled = false;
                    _scheduledDateTime = null;
                  }),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Immediate',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ETA: within ${widget.mechanic.etaMinutes} minutes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCostBreakdown(
      BuildContext context, double servicePrice, bool isAvailable) {
    final gst = servicePrice * 0.18;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.borderSoft),
      ),
      child: Column(
        children: [
          _buildCostRow(context, 'Base Service Charge', '₹${servicePrice.toStringAsFixed(0)}'),
          SizedBox(height: AppSpacing.sm),
          _buildCostRow(context, 'Platform Fee', 'FREE'),
          SizedBox(height: AppSpacing.sm),
          _buildCostRow(context, 'Estimated GST (18% incl.)', '₹${gst.toStringAsFixed(0)}'),
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
            const SnackBar(
              content: Text('Promo codes and loyalty coupons are active for pilot partners.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: context.borderSoft),
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
          Text('Total Payable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary)),
          Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.brandOrange)),
        ],
      ),
    );
  }
}
