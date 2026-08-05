import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/auth/providers/auth_provider.dart';
import 'package:mecha_connect/features/auth/screens/login_screen.dart';
import 'package:mecha_connect/features/profile/navigation.dart';
import 'package:mecha_connect/features/profile/providers/profile_provider.dart';
import 'package:mecha_connect/features/profile/widgets/widgets.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';
import 'package:mecha_connect/theme/theme_provider.dart';
import 'package:mecha_connect/widgets/order_card.dart';

/// Account Center — the Profile home tab.
///
/// Every user-related feature (vehicles, wallet, rewards, orders, addresses,
/// notifications, privacy, support) originates from here. All data streams from
/// the single [ProfileProvider]; every tile navigates — no dead buttons.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ProfileProvider>();
      if (provider.state == ProfileScreenState.initial ||
          provider.state == ProfileScreenState.error) {
        provider.loadHome();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    switch (provider.state) {
      case ProfileScreenState.initial:
      case ProfileScreenState.loading:
        return Scaffold(body: const ProfileLoadingState());
      case ProfileScreenState.error:
        return Scaffold(
          body: ProfileErrorState(
            message: provider.errorMessage ?? 'Unable to load your account.',
            onRetry: provider.loadHome,
          ),
        );
      case ProfileScreenState.ready:
        return Scaffold(
          backgroundColor: context.bgPrimary,
          body: RefreshIndicator(
            onRefresh: provider.refreshHome,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    profile: provider.profile!,
                    rewardPoints: provider.rewards?.redeemablePoints ?? 0,
                    onEdit: () => openEditProfile(context),
                  ),
                ),
                SliverToBoxAdapter(child: _buildStatsRow(context, provider)),
                SliverToBoxAdapter(
                  child: _sectionTitle(
                    context,
                    'My Vehicles',
                    () => openMyVehicles(context),
                  ),
                ),
                SliverToBoxAdapter(child: _buildVehicles(context, provider)),
                SliverToBoxAdapter(
                  child: _sectionTitle(
                    context,
                    'Wallet',
                    () => openWallet(context),
                  ),
                ),
                SliverToBoxAdapter(child: _buildWallet(context, provider)),
                SliverToBoxAdapter(
                  child: _sectionTitle(
                    context,
                    'Orders',
                    () => openOrderHistory(context),
                  ),
                ),
                SliverToBoxAdapter(child: _buildOrders(context, provider)),
                SliverToBoxAdapter(
                  child: _sectionTitle(context, 'Settings', null),
                ),
                SliverToBoxAdapter(child: _buildSettings(context, provider)),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: context.bgSecondary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Profile',
        style: AppTypography.displaySm.copyWith(
          fontSize: 20,
          color: context.textPrimary,
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, ProfileProvider provider) {
    final stats = provider.stats;
    if (stats == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.base,
        AppSpacing.base,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: ProfileStatsCard(
              label: 'Vehicles',
              value: '${stats.vehicles}',
              icon: Icons.directions_car_rounded,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ProfileStatsCard(
              label: 'Services',
              value: '${stats.services}',
              icon: Icons.build_rounded,
              color: AppColors.brandOrange,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ProfileStatsCard(
              label: 'Orders',
              value: '${stats.orders}',
              icon: Icons.shopping_bag_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ProfileStatsCard(
              label: 'Rewards',
              value: '${stats.rewards}',
              icon: Icons.card_giftcard_rounded,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicles(BuildContext context, ProfileProvider provider) {
    final vehicles = provider.vehicles;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        children: [
          for (final vehicle in vehicles.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ProfileVehicleCard(
                vehicle: vehicle,
                onTap: () => openVehicleDetail(context, vehicle),
              ),
            ),
          if (vehicles.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _inlineAddRow(context, 'Add your first vehicle'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _inlineAddRow(context, 'Add Vehicle'),
            ),
        ],
      ),
    );
  }

  Widget _inlineAddRow(BuildContext context, String label) {
    return GestureDetector(
      onTap: () => openMyVehicles(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.bgTertiary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: context.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_rounded,
              size: 20,
              color: AppColors.brandOrange,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.titleSm.copyWith(
                color: AppColors.brandOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWallet(BuildContext context, ProfileProvider provider) {
    final wallet = provider.wallet;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        children: [
          Expanded(
            child: ProfileWalletCard(
              title: 'Balance',
              value: '₹${(wallet?.balance ?? 0).toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.brandOrange,
              subtitle: 'Available',
              onTap: () => openWallet(context),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ProfileWalletCard(
              title: 'Rewards',
              value: '${wallet?.rewardPoints ?? 0}',
              icon: Icons.card_giftcard_rounded,
              color: AppColors.success,
              subtitle: 'Points',
              onTap: () => openRewards(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrders(BuildContext context, ProfileProvider provider) {
    final orders = provider.orders;
    if (orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
        child: Text('No orders yet.'),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        children: [
          for (final order in orders.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: OrderCard(
                title: order['name']?.toString() ?? 'Order',
                subtitle:
                    'Qty: ${order['quantity']} · ${order['brand'] ?? 'Generic'}',
                status: order['status']?.toString(),
                date: order['date']?.toString(),
                total:
                    ((order['price'] as int?) ?? 0) *
                    ((order['quantity'] as int?) ?? 1).toDouble(),
                type: _orderType(order['type']?.toString()),
                onTap: () => openOrderHistory(context),
              ),
            ),
        ],
      ),
    );
  }

  OrderType _orderType(String? value) {
    switch (value) {
      case 'mechanic':
        return OrderType.mechanic;
      case 'fuel':
        return OrderType.fuel;
      case 'aiReport':
        return OrderType.aiReport;
      default:
        return OrderType.parts;
    }
  }

  Widget _buildSettings(BuildContext context, ProfileProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Column(
        children: [
          ProfileMenuTile(
            title: 'Saved Addresses',
            subtitle: '${provider.addresses.length} addresses',
            icon: Icons.location_on_outlined,
            onTap: () => openSavedAddresses(context),
          ),
          Divider(height: 1, color: context.divider, indent: 66),
          ProfileMenuTile(
            title: 'Notifications',
            subtitle: 'Push, email & SMS preferences',
            icon: Icons.notifications_outlined,
            onTap: () => openNotificationSettings(context),
          ),
          Divider(height: 1, color: context.divider, indent: 66),
          ProfileMenuTile(
            title: 'Privacy & Security',
            subtitle: 'Password, app lock, sessions',
            icon: Icons.shield_outlined,
            onTap: () => openPrivacySecurity(context),
          ),
          Divider(height: 1, color: context.divider, indent: 66),
          ProfileMenuTile(
            title: 'Theme',
            subtitle: Provider.of<ThemeProvider>(context).label,
            icon: Icons.dark_mode_outlined,
            onTap: () => _showThemePicker(context),
          ),
          Divider(height: 1, color: context.divider, indent: 66),
          ProfileMenuTile(
            title: 'Support',
            subtitle: 'FAQs, help & feedback',
            icon: Icons.help_outline_rounded,
            onTap: () => openSupport(context),
          ),
          Divider(height: 1, color: context.divider, indent: 66),
          ProfileMenuTile(
            title: 'About Mecha Connect',
            subtitle: 'Version 0.6.0',
            icon: Icons.info_outline_rounded,
            onTap: () => openAbout(context),
          ),
          Divider(height: 1, color: context.divider, indent: 66),
          ProfileMenuTile(
            title: 'Logout',
            icon: Icons.logout_rounded,
            isDestructive: true,
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title,
    VoidCallback? onSeeAll,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.xl,
        AppSpacing.base,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.headlineLg.copyWith(
              color: context.textPrimary,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See All',
                style: AppTypography.titleSm.copyWith(
                  color: AppColors.brandOrange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Log out?'),
            content: const Text(
              'You will need to sign in again to use Mecha Connect.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Log out',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    authProvider.logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showThemePicker(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => SimpleDialog(
            title: const Text('Select Theme'),
            children: [
              SimpleDialogOption(
                child: const Text('Light'),
                onPressed: () {
                  Provider.of<ThemeProvider>(
                    ctx,
                    listen: false,
                  ).setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              SimpleDialogOption(
                child: const Text('Dark'),
                onPressed: () {
                  Provider.of<ThemeProvider>(
                    ctx,
                    listen: false,
                  ).setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
              SimpleDialogOption(
                child: const Text('System'),
                onPressed: () {
                  Provider.of<ThemeProvider>(
                    ctx,
                    listen: false,
                  ).setThemeMode(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
    );
  }
}
