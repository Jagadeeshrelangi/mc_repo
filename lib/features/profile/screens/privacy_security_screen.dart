import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/profile/navigation.dart';
import 'package:mecha_connect/features/profile/providers/profile_provider.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// Password change, app lock and account security options.
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentController;
  late final TextEditingController _newController;
  late final TextEditingController _confirmController;

  bool _appLock = true;
  bool _biometric = false;
  bool _twoFactor = false;
  bool _changingPassword = false;

  @override
  void initState() {
    super.initState();
    _currentController = TextEditingController();
    _newController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _changingPassword = true);
    // Mock backend: password updates are acknowledged after a short wait.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _changingPassword = false);

    _currentController.clear();
    _newController.clear();
    _confirmController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated')),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This action cannot be undone. For security, deletion requests '
            'are completed by our support team.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Contact support', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      openSupport(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Privacy & Security',
          style: AppTypography.titleLg.copyWith(color: context.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          _sectionTitle(context, 'Change password'),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: context.border, width: 1),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _passwordField(_currentController, 'Current password',
                      provider.validatePassword),
                  _passwordField(_newController, 'New password',
                      provider.validateNewPassword),
                  _passwordField(
                    _confirmController,
                    'Confirm new password',
                    (v) => provider.validateConfirmNewPassword(
                        v, _newController.text),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _changingPassword ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.accent,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                      child: _changingPassword
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Security'),
          _switchTile(context, Icons.lock_outline_rounded, 'App lock',
              'Require authentication to open Mecha Connect', _appLock,
              (v) => setState(() => _appLock = v)),
          _switchTile(context, Icons.fingerprint_rounded, 'Biometric unlock',
              'Use your fingerprint or face ID', _biometric,
              (v) => setState(() => _biometric = v)),
          _switchTile(context, Icons.verified_user_outlined, 'Two-step login',
              'Extra code at sign in', _twoFactor,
              (v) => setState(() => _twoFactor = v)),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Active sessions'),
          _sessionTile(context, 'This device', 'Android · Mecha Connect app',
              Icons.smartphone_rounded, isCurrent: true),
          _sessionTile(context, 'Laptop', 'Chrome · Bengaluru',
              Icons.laptop_mac_rounded),
          const SizedBox(height: AppSpacing.xl),
          TextButton.icon(
            onPressed: _deleteAccount,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            label: const Text('Delete account'),
          ),
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

  Widget _passwordField(
    TextEditingController controller,
    String label,
    String? Function(String?)? validator,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        validator: validator,
        style: AppTypography.bodyMd.copyWith(color: context.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline_rounded,
              color: AppColors.brandOrange, size: 20),
          filled: true,
          fillColor: context.bgSecondary,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(color: context.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(color: context.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide:
                const BorderSide(color: AppColors.brandOrange, width: 1.6),
          ),
        ),
      ),
    );
  }

  Widget _switchTile(
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
        onChanged: onChanged,
      ),
    );
  }

  Widget _sessionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    bool isCurrent = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: 20, color: context.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMd.copyWith(color: context.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySm
                      .copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
              child: Text(
                'CURRENT',
                style: AppTypography.overline.copyWith(color: AppColors.success),
              ),
            )
          else
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session revoked')),
                );
              },
              child: Text(
                'Revoke',
                style: AppTypography.titleSm.copyWith(color: AppColors.brandOrange),
              ),
            ),
        ],
      ),
    );
  }
}
