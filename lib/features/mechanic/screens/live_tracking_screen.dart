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

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    try {
      await context.read<MechanicProvider>().loadActiveBooking(
        widget.bookingId,
      );
      if (!mounted) return;
      setState(() => _hasError = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    super.dispose();
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
        body: Center(
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
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${booking.mechanic.etaMinutes} min',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.successDark,
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
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppResponsive.horizontalPadding(context),
        AppSpacing.lg,
        AppResponsive.horizontalPadding(context),
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMechanicInfoCard(context, booking),
          SizedBox(height: AppSpacing.lg),
          _ProgressTimeline(initialStatus: booking.status),
          SizedBox(height: AppSpacing.lg),
          _buildActionButtons(context, booking),
          SizedBox(height: AppSpacing.xxxl),
        ],
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
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.directions_car_rounded,
                      size: 14,
                      color: context.textTertiary,
                    ),
                    SizedBox(width: 4),
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
                    SizedBox(width: 4),
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
                  child: Row(
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
            SizedBox(width: AppSpacing.sm),
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
                  child: Row(
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
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _showCancelDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorLight,
                    foregroundColor: AppColors.error,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: FittedBox(
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
        SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () async {
              await context.read<MechanicProvider>().completeActiveBooking();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => JobCompletedScreen(booking: booking),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Service Completed',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

/// Self-contained status timeline that advances on its own 3s timer. Keeps the
/// ticking isolated so the map placeholder and mechanic card do not rebuild.
class _ProgressTimeline extends StatefulWidget {
  final BookingStatus initialStatus;

  const _ProgressTimeline({required this.initialStatus});

  @override
  State<_ProgressTimeline> createState() => _ProgressTimelineState();
}

class _ProgressTimelineState extends State<_ProgressTimeline> {
  static const List<BookingStatus> _progressStatuses = [
    BookingStatus.requested,
    BookingStatus.accepted,
    BookingStatus.mechanicAssigned,
    BookingStatus.enRoute,
    BookingStatus.arrived,
  ];

  late int _currentStep;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _currentStep =
        widget.initialStatus == BookingStatus.completed
            ? _progressStatuses.length - 1
            : _progressStatuses
                .indexWhere((s) => s == widget.initialStatus)
                .clamp(0, _progressStatuses.length - 1);
    _startProgressTimer();
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_currentStep < _progressStatuses.length - 1) {
        setState(() => _currentStep++);
      } else {
        _progressTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeStatus = _progressStatuses[_currentStep];
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
                'Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Space Grotesk',
                  color: context.textPrimary,
                ),
              ),
              Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandOrangeSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  activeStatus.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandOrange,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.base),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Column(
              key: ValueKey(_currentStep),
              children: [
                for (int i = 0; i < _progressStatuses.length; i++)
                  TimelineTile(
                    title: _progressStatuses[i].label,
                    subtitle: _subtitleFor(i),
                    isCompleted: i < _currentStep,
                    isActive: i == _currentStep,
                    isFirst: i == 0,
                    isLast: i == _progressStatuses.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitleFor(int index) {
    switch (_progressStatuses[index]) {
      case BookingStatus.requested:
        return 'Booking has been requested';
      case BookingStatus.accepted:
        return 'Mechanic accepted your request';
      case BookingStatus.mechanicAssigned:
        return 'Mechanic assigned to your job';
      case BookingStatus.enRoute:
        return index == _currentStep
            ? 'Mechanic is heading to you now'
            : 'Mechanic is en route';
      case BookingStatus.arrived:
        return index == _currentStep
            ? 'Mechanic has arrived'
            : 'Mechanic has reached your location';
      case BookingStatus.completed:
      case BookingStatus.cancelled:
        return '';
    }
  }
}
