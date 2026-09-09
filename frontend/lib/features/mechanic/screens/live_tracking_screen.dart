import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mecha_connect/features/mechanic/models/models.dart';
import 'package:mecha_connect/features/mechanic/providers/mechanic_provider.dart';
import 'package:mecha_connect/features/mechanic/screens/job_completed_screen.dart';
import 'package:mecha_connect/features/mechanic/widgets/timeline_tile.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:provider/provider.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String bookingId;

  const LiveTrackingScreen({super.key, required this.bookingId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  bool _hasError = false;
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    try {
      final provider = context.read<MechanicProvider>();
      await provider.loadActiveBooking(widget.bookingId);
      await provider.fetchActiveBookingEvents();
      if (!mounted) return;
      setState(() => _hasError = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  Future<void> _advanceNextStatus(Booking booking) async {
    BookingStatus? nextStatus;
    switch (booking.status) {
      case BookingStatus.requested:
        nextStatus = BookingStatus.accepted;
        break;
      case BookingStatus.accepted:
        nextStatus = BookingStatus.mechanicAssigned;
        break;
      case BookingStatus.mechanicAssigned:
        nextStatus = BookingStatus.enRoute;
        break;
      case BookingStatus.enRoute:
        nextStatus = BookingStatus.arrived;
        break;
      case BookingStatus.arrived:
        nextStatus = BookingStatus.completed;
        break;
      default:
        return;
    }

    setState(() => _isAdvancing = true);
    try {
      final provider = context.read<MechanicProvider>();
      if (nextStatus == BookingStatus.completed) {
        await provider.completeActiveBooking();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => JobCompletedScreen(booking: provider.activeBooking ?? booking),
          ),
        );
      } else {
        await provider.updateActiveBookingStatus(nextStatus);
        await provider.fetchActiveBookingEvents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdvancing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MechanicProvider>();
    final booking = provider.activeBooking;
    if (booking == null && _hasError) {
      return _buildErrorScreen(context);
    }
    if (booking == null) {
      return Scaffold(
        backgroundColor: context.bgPrimary,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.brandOrange),
        ),
      );
    }
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: ConstrainedContent(
        child: Column(
          children: [
            _buildMapPlaceholder(context, booking),
            Expanded(child: _buildBottomPanel(context, booking)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: context.textTertiary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not load booking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please try again',
                style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _hasError = false);
                    _startTracking();
                  },
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder(BuildContext context, Booking booking) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.35,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.bgTertiary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_rounded, size: 48, color: context.textTertiary),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Live Map',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.textTertiary,
                  ),
                ),
                Text(
                  '(Map integration coming in Sprint 2)',
                  style: TextStyle(fontSize: 12, color: context.textTertiary),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      shape: BoxShape.circle,
                      boxShadow: context.shadowLow,
                    ),
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: booking.status == BookingStatus.completed
                          ? AppColors.successLight
                          : (booking.status == BookingStatus.cancelled
                              ? AppColors.errorLight
                              : AppColors.brandOrangeSoft),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: booking.status == BookingStatus.completed
                                ? AppColors.success
                                : (booking.status == BookingStatus.cancelled
                                    ? AppColors.error
                                    : AppColors.brandOrange),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          booking.status.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: booking.status == BookingStatus.completed
                                ? AppColors.successDark
                                : (booking.status == BookingStatus.cancelled
                                    ? AppColors.error
                                    : AppColors.brandOrange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, Booking booking) {
    return RefreshIndicator(
      onRefresh: _startTracking,
      color: AppColors.brandOrange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppResponsive.horizontalPadding(context),
          AppSpacing.lg,
          AppResponsive.horizontalPadding(context),
          AppSpacing.xxxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMechanicInfoCard(context, booking),
            SizedBox(height: AppSpacing.lg),
            _ProgressTimeline(booking: booking),
            SizedBox(height: AppSpacing.lg),
            _buildActionButtons(context, booking),
            SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildMechanicInfoCard(BuildContext context, Booking booking) {
    final mechanic = booking.mechanic;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.borderSoft),
        boxShadow: context.shadowLow,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.brandOrangeSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 28,
              color: AppColors.brandOrange,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mechanic.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.directions_car_rounded,
                      size: 14,
                      color: context.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booking.vehicle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textTertiary,
                      ),
                    ),
                    SizedBox(width: AppSpacing.base),
                    Icon(
                      Icons.phone_rounded,
                      size: 14,
                      color: context.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      mechanic.phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Booking booking) {
    final isTerminal = booking.status == BookingStatus.completed ||
        booking.status == BookingStatus.cancelled;

    if (booking.status == BookingStatus.cancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.cancel_rounded, color: AppColors.error),
                SizedBox(width: 8),
                Text(
                  'Booking Cancelled',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      );
    }

    if (booking.status == BookingStatus.completed) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => JobCompletedScreen(booking: booking),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('View Invoice & Rating', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      );
    }

    String advanceLabel = 'Acknowledge Request (Pilot)';
    if (booking.status == BookingStatus.accepted) {
      advanceLabel = 'Assign Mechanic (Pilot)';
    } else if (booking.status == BookingStatus.mechanicAssigned) {
      advanceLabel = 'Mechanic En Route (Pilot)';
    } else if (booking.status == BookingStatus.enRoute) {
      advanceLabel = 'Mark Arrived (Pilot)';
    } else if (booking.status == BookingStatus.arrived) {
      advanceLabel = 'Complete Service';
    }

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
                      SnackBar(
                        content: Text('Calling ${booking.mechanic.name}...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_rounded, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Call',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat coming in Sprint 2!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.cardBg,
                    foregroundColor: context.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: context.border),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_rounded, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Chat',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isTerminal ? null : () => _showCancelDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorLight,
                    foregroundColor: AppColors.error,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const FittedBox(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isAdvancing ? null : () => _advanceNextStatus(booking),
            style: ElevatedButton.styleFrom(
              backgroundColor: booking.status == BookingStatus.arrived
                  ? AppColors.success
                  : AppColors.brandOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isAdvancing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    advanceLabel,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCancelDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Cancel Booking?'),
            content: const Text(
              'Are you sure you want to cancel this booking?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep Booking'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Cancel Booking',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final provider = context.read<MechanicProvider>();
    await provider.cancelActiveBooking();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking cancelled'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Truthful status timeline bound directly to the active booking lifecycle state.
class _ProgressTimeline extends StatelessWidget {
  final Booking booking;

  const _ProgressTimeline({required this.booking});

  static const List<BookingStatus> _orderedMilestones = [
    BookingStatus.requested,
    BookingStatus.accepted,
    BookingStatus.mechanicAssigned,
    BookingStatus.enRoute,
    BookingStatus.arrived,
    BookingStatus.completed,
  ];

  int _currentIndex() {
    if (booking.status == BookingStatus.cancelled) return -1;
    final idx = _orderedMilestones.indexOf(booking.status);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final curIdx = _currentIndex();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
              Text(
                'Live Service Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Space Grotesk',
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: booking.status == BookingStatus.cancelled
                      ? AppColors.errorLight
                      : (booking.status == BookingStatus.completed
                          ? AppColors.successLight
                          : AppColors.brandOrangeSoft),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: booking.status == BookingStatus.cancelled
                        ? AppColors.error
                        : (booking.status == BookingStatus.completed
                            ? AppColors.successDark
                            : AppColors.brandOrange),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          Column(
            children: [
              for (int i = 0; i < _orderedMilestones.length; i++)
                TimelineTile(
                  title: _orderedMilestones[i].label,
                  subtitle: _subtitleFor(_orderedMilestones[i], curIdx >= 0 && i <= curIdx),
                  isCompleted: curIdx >= 0 && (booking.status == BookingStatus.completed || i < curIdx),
                  isActive: curIdx >= 0 && i == curIdx && booking.status != BookingStatus.completed,
                  isFirst: i == 0,
                  isLast: i == _orderedMilestones.length - 1,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitleFor(BookingStatus status, bool isPassedOrActive) {
    switch (status) {
      case BookingStatus.requested:
        return 'Booking placed and sent to mechanic';
      case BookingStatus.accepted:
        return isPassedOrActive ? 'Mechanic accepted your request' : 'Awaiting mechanic acceptance';
      case BookingStatus.mechanicAssigned:
        return isPassedOrActive ? 'Mechanic assigned to your job' : 'Assignment pending';
      case BookingStatus.enRoute:
        return isPassedOrActive ? 'Mechanic is on the way' : 'Dispatched after assignment';
      case BookingStatus.arrived:
        return isPassedOrActive ? 'Mechanic reached vehicle location' : 'Pending arrival';
      case BookingStatus.completed:
        return isPassedOrActive ? 'Job completed and verified' : 'Service in progress';
      case BookingStatus.cancelled:
        return 'Booking cancelled';
    }
  }
}
