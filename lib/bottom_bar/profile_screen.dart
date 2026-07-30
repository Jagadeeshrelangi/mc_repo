import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/profile_stat_card.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/wallet_card.dart';
import '../widgets/notification_card.dart';
import '../widgets/settings_tile.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_helpers.dart';
import '../theme/theme_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── User data (placeholder) ──────────────────────────────────────
  final String _userName = 'Jagadeesh Gowda';
  final String _userEmail = 'jagadeesh@mechaconnect.ai';
  final String _userPhone = '+91 98765 43210';
  final String _joinedDate = 'Jan 2025';
  final int _loyaltyPoints = 2450;

  // ── Vehicles ─────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _vehicles = [
    {'name': 'Honda Activa 6G', 'reg': 'KA 01 AB 1234', 'fuel': 'Petrol', 'lastService': 'Mar 2025', 'health': 92, 'isDefault': true},
    {'name': 'Maruti Swift', 'reg': 'KA 02 CD 5678', 'fuel': 'Diesel', 'lastService': 'Jan 2025', 'health': 78, 'isDefault': false},
  ];

  // ── Notifications ────────────────────────────────────────────────
  final List<Map<String, dynamic>> _notifications = [
    {'title': 'Service Completed', 'message': 'Your Honda Activa service is complete. Ready for pickup.', 'time': '2 hours ago', 'unread': true, 'icon': Icons.check_circle_rounded},
    {'title': 'Parts Delivered', 'message': 'Brake pads for Maruti Swift have been delivered.', 'time': 'Yesterday', 'unread': true, 'icon': Icons.local_shipping_rounded},
    {'title': 'AI Diagnosis', 'message': 'New diagnostic report available for your vehicle.', 'time': '2 days ago', 'unread': false, 'icon': Icons.psychology_rounded},
    {'title': 'Loyalty Reward', 'message': 'You earned 150 points for your recent service!', 'time': '3 days ago', 'unread': false, 'icon': Icons.card_giftcard_rounded},
    {'title': 'Payment Received', 'message': '₹2,450 payment confirmed for Order #1234.', 'time': '5 days ago', 'unread': false, 'icon': Icons.payments_rounded},
  ];

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark),
          SliverToBoxAdapter(child: _buildProfileHeader(isDark)),
          SliverToBoxAdapter(child: _buildStatsRow()),
          SliverToBoxAdapter(child: _buildSectionTitle('My Vehicles', 'See All')),
          SliverToBoxAdapter(child: _buildVehicles()),
          SliverToBoxAdapter(child: _buildSectionTitle('Wallet', '')),
          SliverToBoxAdapter(child: _buildWallet()),
          SliverToBoxAdapter(child: _buildSectionTitle('Notifications', 'Clear All')),
          SliverToBoxAdapter(child: _buildNotifications()),
          SliverToBoxAdapter(child: _buildSectionTitle('Settings', '')),
          SliverToBoxAdapter(child: _buildSettings()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: context.bgSecondary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Profile',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Space Grotesk',
          color: context.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _navigateToPlaceholder(context, 'Edit Profile'),
          icon: Icon(Icons.edit_rounded, size: 22, color: context.textSecondary),
          tooltip: 'Edit profile',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.person_rounded, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Space Grotesk',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userPhone,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Badges row
          Row(
            children: [
              _buildBadge(Icons.workspace_premium_rounded, 'Pro Member'),
              const SizedBox(width: 8),
              _buildBadge(Icons.star_rounded, '$_loyaltyPoints pts'),
              const SizedBox(width: 8),
              _buildBadge(Icons.calendar_today_rounded, _joinedDate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: ProfileStatCard(
              label: 'Vehicles',
              value: '${_vehicles.length}',
              icon: Icons.directions_car_rounded,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ProfileStatCard(
              label: 'Services',
              value: '12',
              icon: Icons.build_rounded,
              color: AppColors.brandOrange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ProfileStatCard(
              label: 'Orders',
              value: '8',
              icon: Icons.shopping_bag_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ProfileStatCard(
              label: 'Rewards',
              value: '$_loyaltyPoints',
              icon: Icons.card_giftcard_rounded,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String action) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFamily: 'Space Grotesk',
              color: context.textPrimary,
            ),
          ),
          if (action.isNotEmpty)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$action coming soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandOrange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ..._vehicles.map((v) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: VehicleCard(
              name: v['name'],
              registration: v['reg'],
              fuelType: v['fuel'],
              lastService: v['lastService'],
              healthScore: v['health'],
              isDefault: v['isDefault'],
              onTap: () => _navigateToPlaceholder(context, 'Vehicle Details: ${v['name']}'),
            ),
          )),
          // Add vehicle
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add vehicle coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.bgTertiary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.border, width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 20, color: AppColors.brandOrange),
                  SizedBox(width: 8),
                  Text(
                    'Add Vehicle',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandOrange,
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

  Widget _buildWallet() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: WalletCard(
              title: 'Balance',
              value: '₹1,200',
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.brandOrange,
              subtitle: 'Available',
              onTap: () => _navigateToPlaceholder(context, 'Wallet'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: WalletCard(
              title: 'Rewards',
              value: '$_loyaltyPoints',
              icon: Icons.card_giftcard_rounded,
              color: AppColors.success,
              subtitle: 'Points',
              onTap: () => _navigateToPlaceholder(context, 'Rewards'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifications() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _notifications.take(3).map((n) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
            child: NotificationCard(
            title: n['title'],
            message: n['message'],
            time: n['time'],
            isUnread: n['unread'],
            icon: n['icon'],
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${n['title']} — marking as read'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSettings() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Column(
        children: [
          SettingsTile(
            title: 'Notifications',
            subtitle: 'Manage push & email',
            icon: Icons.notifications_outlined,
            onTap: () => _navigateToPlaceholder(context, 'Notification Settings'),
          ),
          Divider(height: 1, color: context.divider, indent: 66),
          SettingsTile(
            title: 'Privacy & Security',
            subtitle: 'Password, 2FA',
            icon: Icons.shield_outlined,
            onTap: () => _navigateToPlaceholder(context, 'Privacy & Security'),
          ),
          Divider(height: 1, color: context.divider, indent: 66),
          SettingsTile(
            title: 'Language',
            subtitle: 'English',
            icon: Icons.language_rounded,
            onTap: () => _navigateToPlaceholder(context, 'Language Settings'),
          ),
          Divider(height: 1, color: context.divider, indent: 66),
          SettingsTile(
            title: 'Theme',
            subtitle: Provider.of<ThemeProvider>(context).label,
            icon: Icons.dark_mode_outlined,
            onTap: () => _showThemePicker(),
          ),
          Divider(height: 1, color: context.divider, indent: 66),
          SettingsTile(
            title: 'Help & Support',
            subtitle: 'FAQs, Contact us',
            icon: Icons.help_outline_rounded,
            onTap: () => _navigateToPlaceholder(context, 'Help & Support'),
          ),
          Divider(height: 1, color: context.divider, indent: 66),
          SettingsTile(
            title: 'About Mecha Connect',
            subtitle: 'Version 0.6.0',
            icon: Icons.info_outline_rounded,
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Mecha Connect',
                applicationVersion: '0.6.0',
                applicationIcon: const Icon(Icons.directions_car_rounded, color: AppColors.brandOrange, size: 32),
                children: const [
                  Text('AI-powered roadside assistance platform for India.'),
                ],
              );
            },
          ),
          Divider(height: 1, color: context.divider, indent: 66),
          SettingsTile(
            title: 'Logout',
            icon: Icons.logout_rounded,
            isDestructive: true,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToPlaceholder(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(
            child: Text(
              '$title coming soon!',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  void _showThemePicker() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Theme'),
        children: [
          SimpleDialogOption(
            child: const Text('Light'),
            onPressed: () {
              Provider.of<ThemeProvider>(ctx, listen: false).setThemeMode(ThemeMode.light);
              Navigator.pop(ctx);
            },
          ),
          SimpleDialogOption(
            child: const Text('Dark'),
            onPressed: () {
              Provider.of<ThemeProvider>(ctx, listen: false).setThemeMode(ThemeMode.dark);
              Navigator.pop(ctx);
            },
          ),
          SimpleDialogOption(
            child: const Text('System'),
            onPressed: () {
              Provider.of<ThemeProvider>(ctx, listen: false).setThemeMode(ThemeMode.system);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
