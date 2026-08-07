import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/ai/providers/ai_provider.dart';
import 'package:mecha_connect/features/auth/providers/auth_provider.dart';
import 'package:mecha_connect/features/auth/repositories/auth_repository.dart';
import 'package:mecha_connect/features/auth/services/auth_service.dart';
import 'package:mecha_connect/features/fuel_delivery/providers/fuel_provider.dart';
import 'package:mecha_connect/features/home/providers/home_provider.dart';
import 'package:mecha_connect/features/home/repositories/home_repository.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/features/mechanic/providers/mechanic_provider.dart';
import 'package:mecha_connect/features/profile/providers/profile_provider.dart';
import 'package:mecha_connect/features/profile/repositories/profile_repository.dart';
import 'package:mecha_connect/services/location_provider.dart';
import 'package:mecha_connect/theme/theme_provider.dart';

/// Single source of truth for the app's root provider graph.
///
/// `main()` and the runtime regression test both build from here, so the test
/// exercises the EXACT production wiring — one [MarketplaceProvider] above
/// `MaterialApp` — instead of a test-local wrapper that can drift.
List<SingleChildWidget> buildRootProviders({
  LocationProvider? locationProvider,
  FuelProvider? fuelProvider,
  MarketplaceProvider? marketplaceProvider,
  ProfileProvider? profileProvider,
}) {
  final location = locationProvider ?? LocationProvider();
  final fuel = fuelProvider ?? FuelProvider(locationProvider: location);
  final marketplace = marketplaceProvider ?? MarketplaceProvider();
  final profile = profileProvider ??
      ProfileProvider(
        repository: ProfileRepository(
          notificationSettingsStore: SharedPreferencesNotificationSettingsStore(),
        ),
      );

  return [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider.value(value: location),
    ChangeNotifierProvider(
      create: (_) => AuthProvider(AuthService(AuthRepository())),
    ),
    ChangeNotifierProvider(create: (_) => HomeProvider(HomeRepository())),
    ChangeNotifierProvider(create: (_) => MechanicProvider()),
    ChangeNotifierProvider(create: (_) => AiProvider()),
    ChangeNotifierProvider.value(value: profile),
    ChangeNotifierProvider.value(value: fuel),
    ChangeNotifierProvider.value(value: marketplace),
  ];
}
