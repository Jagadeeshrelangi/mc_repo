import 'package:flutter/material.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/features/profile/screens/screens.dart';

const String profileHomeRoute = '/profile';
const String profileEditRoute = '/profile/edit';
const String profileVehiclesRoute = '/profile/vehicles';
const String profileVehicleDetailRoute = '/profile/vehicles/detail';
const String profileAddressesRoute = '/profile/addresses';
const String profileWalletRoute = '/profile/wallet';
const String profileRewardsRoute = '/profile/rewards';
const String profileOrdersRoute = '/profile/orders';
const String profileNotificationsRoute = '/profile/notifications';
const String profilePrivacyRoute = '/profile/privacy';
const String profileSupportRoute = '/profile/support';
const String profileAboutRoute = '/profile/about';

/// Fade-through page transition used across Profile screens (matches the
/// Marketplace / AI transition language).
Route<void> profileFadeRoute(Widget screen) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, animation, secondaryAnimation) =>
        FadeTransition(opacity: animation, child: screen),
  );
}

void openEditProfile(BuildContext context) {
  Navigator.of(context).push(profileFadeRoute(const EditProfileScreen()));
}

void openMyVehicles(BuildContext context) {
  Navigator.of(context).push(profileFadeRoute(const MyVehiclesScreen()));
}

void openVehicleDetail(BuildContext context, ProfileVehicle vehicle) {
  Navigator.of(context)
      .push(profileFadeRoute(VehicleDetailScreen(vehicle: vehicle)));
}

void openSavedAddresses(BuildContext context) {
  Navigator.of(context).push(profileFadeRoute(const SavedAddressesScreen()));
}

void openWallet(BuildContext context) {
  Navigator.of(context).push(profileFadeRoute(const WalletScreen()));
}

void openRewards(BuildContext context) {
  Navigator.of(context).push(profileFadeRoute(const RewardsScreen()));
}

void openOrderHistory(BuildContext context) {
  Navigator.of(context).push(profileFadeRoute(const OrderHistoryScreen()));
}

void openNotificationSettings(BuildContext context) {
  Navigator.of(context)
      .push(profileFadeRoute(const NotificationSettingsScreen()));
}

void openPrivacySecurity(BuildContext context) {
  Navigator.of(context).push(profileFadeRoute(const PrivacySecurityScreen()));
}

void openSupport(BuildContext context) {
  Navigator.of(context).push(profileFadeRoute(const SupportScreen()));
}

void openAbout(BuildContext context) {
  Navigator.of(context).push(profileFadeRoute(const AboutScreen()));
}
