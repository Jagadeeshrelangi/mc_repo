import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/features/profile/providers/profile_provider.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// Notification channel toggles, persisted locally.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late NotificationSettings _local;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _local = context.read<ProfileProvider>().notificationSettings;
  }

  Future<void> _save(NotificationSettings next) async {
    setState(() {
      _local = next;
      _saving = true;
    });
    final ok =
        await context.read<ProfileProvider>().saveNotificationSettings(next);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.read<ProfileProvider>().operationError ??
                'Unable to save notification settings')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notifications',
          style: AppTypography.titleLg.copyWith(color: context.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.base),
            child: _saving
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          _tile(context, Icons.notifications_active_outlined,
              'Order updates', 'Service status and delivery updates', _local.push,
              (v) => _save(_local.copyWith(push: v))),
          _tile(context, Icons.mail_outline_rounded,
              'Email notifications', 'Receipts and monthly summaries',
              _local.email, (v) => _save(_local.copyWith(email: v))),
          _tile(context, Icons.sms_outlined,
              'SMS alerts', 'Critical service reminders',
              _local.sms, (v) => _save(_local.copyWith(sms: v))),
          _tile(context, Icons.campaign_outlined,
              'Offers & promotions', 'Deals from nearby workshops and stores',
              _local.marketing, (v) => _save(_local.copyWith(marketing: v))),
          _tile(context, Icons.sos_rounded,
              'Emergency alerts', 'Roadside assistance and safety alerts',
              _local.emergencyAlerts,
              (v) => _save(_local.copyWith(emergencyAlerts: v))),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.border, width: 1),
      ),
      child: SwitchListTile(
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, size: 20, color: context.accent),
        ),
        title: Text(
          title,
          style: AppTypography.titleMd.copyWith(color: context.textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySm.copyWith(color: context.textSecondary),
        ),
        value: value,
        activeTrackColor: AppColors.brandOrange,
        onChanged: _saving ? null : onChanged,
      ),
    );
  }
}
