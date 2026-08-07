import 'package:flutter/material.dart';
import 'package:mecha_connect/features/auth/screens/login_screen.dart';
import 'package:mecha_connect/features/auth/providers/auth_provider.dart';
import 'package:mecha_connect/features/profile/navigation.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/bottom_bar/order_screen.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: context.cardBg,
      child: SafeArea(
        child: Column(
          children: [
            // Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.darkSurface, AppColors.darkBg]
                      : [AppColors.brandOrange, AppColors.brandOrangeDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkPrimary : Colors.white).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isDark ? AppColors.darkPrimary : Colors.white).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'JG',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Jagadeesh Gowda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'jagadeesh@mechaconnect.ai',
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Bike \u2022 Honda Activa 6G',
                      style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuItem(context, icon: Icons.home_rounded, title: 'Home', onTap: () => Navigator.pop(context)),
                  _buildMenuItem(context, icon: Icons.receipt_long_rounded, title: 'My Orders', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const Orderscreen()));
                  }),
                  _buildMenuItem(context, icon: Icons.account_balance_wallet_rounded, title: 'Wallet', onTap: () {
                    Navigator.pop(context);
                    openWallet(context);
                  }),
                  _buildMenuItem(context, icon: Icons.directions_car_rounded, title: 'My Vehicles', onTap: () {
                    Navigator.pop(context);
                    openMyVehicles(context);
                  }),
                  _buildMenuItem(context, icon: Icons.notifications_rounded, title: 'Notifications', onTap: () {
                    Navigator.pop(context);
                    openNotificationSettings(context);
                  }),
                  _buildMenuItem(context, icon: Icons.settings_rounded, title: 'Settings', onTap: () {
                    Navigator.pop(context);
                    openPrivacySecurity(context);
                  }),
                  _buildMenuItem(context, icon: Icons.help_outline_rounded, title: 'Help & Support', onTap: () {
                    Navigator.pop(context);
                    openSupport(context);
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(color: context.divider),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    color: AppColors.error,
                    onTap: () {
                      // ignore: use_build_context_synchronously
                      Provider.of<AuthProvider>(context, listen: false).logout();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Mecha Connect v0.6.0',
                style: TextStyle(
                  fontSize: 11,
                  color: context.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(icon, size: 22, color: color ?? context.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color ?? context.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: context.border,
      ),
      onTap: onTap,
    );
  }
}
