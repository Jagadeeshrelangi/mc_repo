import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/mechanic/mock_data.dart';
import 'package:mecha_connect/mechanic/widgets/timeline_tile.dart';
import 'package:mecha_connect/mechanic/screens/job_completed_screen.dart';

class LiveTrackingScreen extends StatelessWidget {
  final MechanicInfo mechanic;
  final MechanicService service;
  final double totalCost;

  const LiveTrackingScreen({
    super.key,
    required this.mechanic,
    required this.service,
    required this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: ConstrainedContent(
        child: Column(
          children: [
            _buildMapPlaceholder(context),
            Expanded(child: _buildBottomPanel(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.35,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.bgTertiary,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_rounded, size: 48, color: context.textTertiary),
                SizedBox(height: AppSpacing.sm),
                Text('Live Map', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textTertiary)),
                Text('(Map integration coming soon)', style: TextStyle(fontSize: 12, color: context.textTertiary)),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(color: context.cardBg, shape: BoxShape.circle, boxShadow: context.shadowLow),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                        SizedBox(width: 4),
                        Text('${mechanic.etaMinutes} min', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.successDark)),
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

  Widget _buildBottomPanel(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(AppResponsive.horizontalPadding(context), AppSpacing.lg, AppResponsive.horizontalPadding(context), 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMechanicInfoCard(context),
          SizedBox(height: AppSpacing.lg),
          _buildStatusTimeline(context),
          SizedBox(height: AppSpacing.lg),
          _buildActionButtons(context),
          SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildMechanicInfoCard(BuildContext context) {
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
            width: 52, height: 52,
            decoration: BoxDecoration(color: AppColors.brandOrangeSoft, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.person_rounded, size: 28, color: AppColors.brandOrange),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mechanic.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.directions_car_rounded, size: 14, color: context.textTertiary),
                    SizedBox(width: 4),
                    Text('Honda Activa 6G', style: TextStyle(fontSize: 12, color: context.textTertiary)),
                    SizedBox(width: AppSpacing.base),
                    Icon(Icons.phone_rounded, size: 14, color: context.textTertiary),
                    SizedBox(width: 4),
                    Text(mechanic.phone, style: TextStyle(fontSize: 12, color: context.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(BuildContext context) {
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
          Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary)),
          SizedBox(height: AppSpacing.base),
          TimelineTile(title: 'Booking Confirmed', subtitle: 'Booking has been confirmed', isCompleted: true, isFirst: true),
          TimelineTile(title: 'Mechanic Assigned', subtitle: '${mechanic.name} assigned', isCompleted: true),
          TimelineTile(title: 'On The Way', subtitle: 'Mechanic is en route', isActive: true),
          TimelineTile(title: 'Arrived', subtitle: 'Mechanic has arrived'),
          TimelineTile(title: 'Service Started', subtitle: 'Work in progress'),
          TimelineTile(title: 'Completed', subtitle: 'Job finished', isLast: true),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
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
                      SnackBar(content: Text('Calling ${mechanic.name}...'), behavior: SnackBarBehavior.floating),
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
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat feature coming soon!'), behavior: SnackBarBehavior.floating),
                    );
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
                      Icon(Icons.chat_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Chat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cancel Booking?'),
                        content: const Text('Are you sure you want to cancel this booking?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Booking')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            child: const Text('Cancel Booking', style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorLight,
                    foregroundColor: AppColors.error,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: FittedBox(
                    child: Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
            onPressed: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => JobCompletedScreen(
                  mechanic: mechanic,
                  service: service,
                  totalCost: totalCost,
                ),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Service Completed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }


}
