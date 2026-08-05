import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// App info, feature overview and legal links.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _features = [
    'Auto-detect GPS location for pickups',
    'AI vehicle health reports',
    'Multi-category orders (parts, mechanic, fuel)',
    'Wallet with reward points & coupons',
    'Saved addresses, vehicles and emergency contact',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'About Mecha Connect',
          style: AppTypography.titleLg.copyWith(color: context.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: const Icon(Icons.directions_car_rounded,
                  size: 44, color: Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              'Mecha Connect',
              style: AppTypography.headlineLg.copyWith(color: context.textPrimary),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              'Version 0.6.0',
              style: AppTypography.bodySm.copyWith(color: context.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'One app for everything your vehicle needs — genuine parts, '
            'on-demand mechanics, doorstep fuel and AI-powered health '
            'reports. Built for the roads of India.',
            style: AppTypography.bodyMd.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, 'What you can do'),
          for (final feature in _features) _featureRow(context, feature),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, 'Legal'),
          _linkTile(context, Icons.privacy_tip_outlined, 'Privacy Policy',
              () => _showLegalDialog(context, 'Privacy Policy',
                  'Mecha Connect collects only the data needed to provide '
                  'services. Your location is used with permission for '
                  'pickup and delivery. We never sell personal data.')),
          _linkTile(context, Icons.description_outlined, 'Terms of Service',
              () => _showLegalDialog(context, 'Terms of Service',
                  'By using Mecha Connect you agree to fair use of the '
                  'marketplace, wallet and reward services. Refunds follow '
                  'the cancellation policy shown at checkout.')),
          _linkTile(context, Icons.code_rounded, 'Open source licenses',
              () => showLicensePage(
                    context: context,
                    applicationName: 'Mecha Connect',
                  )),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.headlineMd.copyWith(color: context.textPrimary),
      ),
    );
  }

  Widget _featureRow(BuildContext context, String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 18, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              feature,
              style: AppTypography.bodyMd.copyWith(color: context.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkTile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.border, width: 1),
      ),
      child: ListTile(
        leading: Icon(icon, color: context.accent, size: 22),
        title: Text(
          label,
          style: AppTypography.titleMd.copyWith(color: context.textPrimary),
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            size: 20, color: AppColors.grey300),
        onTap: onTap,
      ),
    );
  }

  void _showLegalDialog(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
