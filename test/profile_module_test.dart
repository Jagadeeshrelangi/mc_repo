import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/features/profile/providers/profile_provider.dart';
import 'package:mecha_connect/features/profile/repositories/profile_repository.dart';
import 'package:mecha_connect/features/profile/screens/edit_profile_screen.dart';
import 'package:mecha_connect/features/profile/screens/my_vehicles_screen.dart';
import 'package:mecha_connect/features/profile/screens/profile_screen.dart';
import 'package:mecha_connect/features/profile/screens/saved_addresses_screen.dart';
import 'package:mecha_connect/features/profile/services/profile_service.dart';
import 'package:mecha_connect/features/profile/services/validation_service.dart';
import 'package:mecha_connect/features/profile/widgets/profile_header.dart';
import 'package:mecha_connect/parts/order_data.dart';
import 'package:mecha_connect/theme/theme_provider.dart';
import 'package:provider/provider.dart';

/// Zero-latency repository so unit tests never wait on the mock 800ms delay.
ProfileRepository _fastRepo({int failForFirstCalls = 0}) {
  return ProfileRepository(
    latency: Duration.zero,
    failForFirstCalls: failForFirstCalls,
    notificationSettingsStore: InMemoryNotificationSettingsStore(),
  );
}

/// Repository that fails the NEXT load after a successful one — used to prove
/// a failed pull-to-refresh never wipes the data already on screen.
class _FlakyRefreshRepo extends ProfileRepository {
  _FlakyRefreshRepo()
      : super(
          latency: Duration.zero,
          notificationSettingsStore: InMemoryNotificationSettingsStore(),
        );

  bool failNextRefresh = false;

  @override
  Future<UserProfile> fetchProfile() async {
    if (failNextRefresh) {
      failNextRefresh = false;
      throw const ProfileNetworkException();
    }
    return super.fetchProfile();
  }
}

/// Pumps [child] under a single [ProfileProvider] (mirrors the root wiring
/// that `app_wiring.dart` provides to the real app).
Widget _wrap(Widget child, {ProfileProvider? provider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider.value(
        value: provider ?? ProfileProvider(repository: _fastRepo()),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('ProfileRepository', () {
    test('seeds profile, vehicles and addresses with default-first order',
        () async {
      final repository = _fastRepo();

      final profile = await repository.fetchProfile();
      expect(profile.name, 'Jagadeesh Gowda');
      expect(profile.email, 'jagadeesh@mechaconnect.ai');
      expect(profile.membershipTier, MembershipTier.pro);
      expect(profile.emergencyContact!.name, 'Priya Gowda');

      final vehicles = await repository.fetchVehicles();
      expect(vehicles.length, 2);
      expect(vehicles.first.isDefault, isTrue);

      final addresses = await repository.fetchAddresses();
      expect(addresses.length, 2);
      expect(addresses.first.isDefault, isTrue);
      expect(addresses.first.label, AddressLabel.home);
    });

    test('fails for the first N calls then succeeds', () async {
      final repository = _fastRepo(failForFirstCalls: 1);

      await expectLater(
        repository.fetchProfile(),
        throwsA(isA<ProfileNetworkException>()),
      );
      final profile = await repository.fetchProfile();
      expect(profile.name, isNotEmpty);
    });

    test('addVehicle appends, promotes default and assigns an id', () async {
      final repository = _fastRepo();

      final created = await repository.addVehicle(
        const ProfileVehicle(
          id: '',
          brand: 'TVS',
          model: 'Apache RTR',
          registration: 'KA 03 EF 9999',
          fuelType: VehicleFuel.petrol,
          isDefault: true,
        ),
      );

      expect(created.length, 3);
      expect(created.first.isDefault, isTrue);
      expect(created.first.brand, 'TVS');
      expect(created.first.id, isNotEmpty);
    });

    test('setDefaultVehicle promotes exactly one vehicle', () async {
      final repository = _fastRepo();

      final updated = await repository.setDefaultVehicle('veh-102');
      final defaults = updated.where((v) => v.isDefault).toList();
      expect(defaults.length, 1);
      expect(defaults.single.id, 'veh-102');
    });

    test('deleteVehicle re-promotes the first when no default remains',
        () async {
      final repository = _fastRepo();

      final updated = await repository.deleteVehicle('veh-101');
      expect(updated.length, 1);
      expect(updated.single.isDefault, isTrue);
    });

    test('address CRUD keeps a single default', () async {
      final repository = _fastRepo();

      final added = await repository.addAddress(
        const SavedAddress(
          id: 'addr-new',
          label: AddressLabel.office,
          address: '2nd Floor, Tech Park, Hyderabad',
          latitude: 17.3850,
          longitude: 78.4867,
          isDefault: true,
        ),
      );
      expect(added.length, 3);
      expect(added.firstWhere((a) => a.isDefault).id, 'addr-new');

      final reverted = await repository.setDefaultAddress('addr-101');
      expect(reverted.firstWhere((a) => a.isDefault).id, 'addr-101');

      final removed = await repository.deleteAddress('addr-102');
      expect(removed.length, 2);
    });

    test('wallet and rewards snapshots match the seeded values', () async {
      final repository = _fastRepo();

      final wallet = await repository.fetchWallet();
      expect(wallet.balance, 1200);
      expect(wallet.rewardPoints, 2450);
      expect(wallet.transactions.length, 4);
      expect(wallet.coupons.length, 2);
      expect(wallet.paymentMethods.length, 2);

      final rewards = await repository.fetchRewards();
      expect(rewards.redeemablePoints, 2450);
      expect(rewards.referralCode, 'GOWDA200');
      expect(rewards.rewards.length, 4);
      expect(rewards.achievements.length, 4);
    });

    test('order history reads the SAME store the Orders tab renders',
        () async {
      final repository = _fastRepo();
      final orders = await repository.fetchOrders();
      final stats = await repository.fetchStats();

      expect(orders.length, ordersList.length);
      expect(stats.orders, ordersList.length);
    });

    test('notification settings round-trip through the injected store',
        () async {
      final store = InMemoryNotificationSettingsStore();
      final repository = ProfileRepository(
        latency: Duration.zero,
        notificationSettingsStore: store,
      );

      final initial = await repository.fetchNotificationSettings();
      expect(initial.push, isTrue);

      final saved = await repository.saveNotificationSettings(
        initial.copyWith(push: false, marketing: true),
      );
      expect(saved.push, isFalse);
      expect(saved.marketing, isTrue);

      final reloaded = await repository.fetchNotificationSettings();
      expect(reloaded.push, isFalse);
      expect(reloaded.marketing, isTrue);
    });
  });

  group('ValidationService', () {
    test('profile field rules', () {
      expect(ValidationService.fullName(''), 'Enter your full name');
      expect(ValidationService.fullName('J'), isNotNull);
      expect(ValidationService.fullName('Jagadeesh'), isNull);

      expect(ValidationService.email('nope'), isNotNull);
      expect(ValidationService.email('jagadeesh@mechaconnect.ai'), isNull);

      expect(ValidationService.phone('12345'), isNotNull);
      expect(ValidationService.phone('+91 98765 43210'), isNull);

      expect(ValidationService.registration('KA 01 AB 1234'), isNull);
      expect(ValidationService.registration('bad'), isNotNull);

      expect(ValidationService.address('short'), isNotNull);
      expect(ValidationService.address('12-3-45, Main Road, Surampalem'), isNull);

      expect(ValidationService.newPassword('12345'), isNotNull);
      expect(ValidationService.newPassword('secret1'), isNull);
      expect(ValidationService.confirmNewPassword('x', 'y'), isNotNull);
      expect(ValidationService.confirmNewPassword('s', 's'), isNull);
    });
  });

  group('ProfileService', () {
    test('validateProfileForm accepts a valid payload', () {
      final service = ProfileService(repository: _fastRepo());
      expect(
        service.validateProfileForm(
          name: 'Jagadeesh Gowda',
          email: 'jagadeesh@mechaconnect.ai',
          phone: '+91 98765 43210',
          dateOfBirth: DateTime(1995, 4, 12),
          gender: 'Male',
        ),
        isNull,
      );
    });

    test('validateProfileForm rejects a bad email and bad emergency phone',
        () {
      final service = ProfileService(repository: _fastRepo());
      expect(
        service.validateProfileForm(
          name: 'Jagadeesh Gowda',
          email: 'nope',
          phone: '+91 98765 43210',
        ),
        'Enter a valid email address',
      );

      expect(
        service.validateProfileForm(
          name: 'Jagadeesh Gowda',
          email: 'jagadeesh@mechaconnect.ai',
          phone: '+91 98765 43210',
          dateOfBirth: DateTime(1995, 4, 12),
          gender: 'Male',
          emergencyContact:
              const EmergencyContact(name: 'X', relation: 'Sister', phone: 'bad'),
        ),
        'Check the emergency contact details',
      );
    });
  });

  group('ProfileProvider', () {
    test('loadHome seeds every surface and moves to ready', () async {
      final provider = ProfileProvider(repository: _fastRepo());
      await provider.loadHome();

      expect(provider.state, ProfileScreenState.ready);
      expect(provider.profile!.name, 'Jagadeesh Gowda');
      expect(provider.vehicles.length, 2);
      expect(provider.addresses.length, 2);
      expect(provider.wallet!.balance, 1200);
      expect(provider.rewards!.referralCode, 'GOWDA200');
      expect(provider.orders.length, ordersList.length);
      expect(provider.stats!.vehicles, 2);
      expect(provider.notificationSettings.push, isTrue);
    });

    test('loadHome surfaces an error state and retry recovers', () async {
      final provider =
          ProfileProvider(repository: _fastRepo(failForFirstCalls: 1));

      await provider.loadHome();
      expect(provider.state, ProfileScreenState.error);
      expect(provider.errorMessage, isNotNull);

      await provider.loadHome();
      expect(provider.state, ProfileScreenState.ready);
    });

    test('refreshHome keeps the loaded data when the refresh fails', () async {
      final repo = _FlakyRefreshRepo();
      final provider = ProfileProvider(repository: repo);
      await provider.loadHome();
      expect(provider.state, ProfileScreenState.ready);
      expect(provider.profile!.name, 'Jagadeesh Gowda');
      expect(provider.vehicles.length, 2);

      // The next refresh explodes; the data already on screen must survive.
      repo.failNextRefresh = true;
      await provider.refreshHome();

      expect(provider.vehicles.length, 2);
      expect(provider.profile!.name, 'Jagadeesh Gowda');
      expect(provider.state, ProfileScreenState.ready);
    });

    test('updateProfile persists account changes', () async {
      final provider = ProfileProvider(repository: _fastRepo());
      await provider.loadHome();

      final ok = await provider.updateProfile(
        provider.profile!.copyWith(name: 'Jagadeesh R Gowda'),
      );
      expect(ok, isTrue);
      expect(provider.profile!.name, 'Jagadeesh R Gowda');
    });

    test('vehicle lifecycle manages the single vehicle list', () async {
      final provider = ProfileProvider(repository: _fastRepo());
      await provider.loadHome();

      expect(
        await provider.addVehicle(const ProfileVehicle(
          id: '',
          brand: 'TVS',
          model: 'Apache RTR',
          registration: 'KA 03 EF 9999',
          fuelType: VehicleFuel.petrol,
        )),
        isTrue,
      );
      expect(provider.vehicles.length, 3);

      expect(await provider.setDefaultVehicle('veh-102'), isTrue);
      expect(provider.defaultVehicle!.id, 'veh-102');

      expect(await provider.deleteVehicle('veh-102'), isTrue);
      expect(provider.vehicles.length, 2);
    });

    test('address lifecycle manages the single address list', () async {
      final provider = ProfileProvider(repository: _fastRepo());
      await provider.loadHome();

      expect(
        await provider.addAddress(const SavedAddress(
          id: '',
          label: AddressLabel.other,
          address: '2nd Floor, Tech Park, Hyderabad',
          latitude: 17.3850,
          longitude: 78.4867,
        )),
        isTrue,
      );
      expect(provider.addresses.length, 3);

      expect(await provider.setDefaultAddress('addr-102'), isTrue);
      expect(provider.addresses.firstWhere((a) => a.isDefault).id, 'addr-102');

      expect(await provider.deleteAddress('addr-101'), isTrue);
      expect(provider.addresses.length, 2);
    });

    test('saveNotificationSettings persists and exposes the error path',
        () async {
      final provider = ProfileProvider(repository: _fastRepo());
      await provider.loadHome();

      final ok = await provider.saveNotificationSettings(
        provider.notificationSettings.copyWith(marketing: true),
      );
      expect(ok, isTrue);
      expect(provider.notificationSettings.marketing, isTrue);

      // A failing repository surfaces the operation error.
      final failing = ProfileProvider(
        repository: _fastRepo(failForFirstCalls: 1),
      );
      final failed = await failing.saveNotificationSettings(
        const NotificationSettings(),
      );
      expect(failed, isFalse);
      expect(failing.operationError, isNotNull);
    });

    test('validation passthroughs reach the single ValidationService', () {
      final provider = ProfileProvider(repository: _fastRepo());
      expect(provider.validateFullName(''), 'Enter your full name');
      expect(provider.validateEmail('jagadeesh@mechaconnect.ai'), isNull);
      expect(provider.validateRegistration('KA 01 AB 1234'), isNull);
      expect(provider.validateNewPassword('12345'), isNotNull);
    });
  });

  group('ProfileScreen', () {
    testWidgets('renders header, stats and settings after loading',
        (tester) async {
      // A tall viewport keeps every sliver built so the full account center
      // (header → stats → vehicles → wallet → orders → settings → logout) is
      // assertable without scrolling a lazy CustomScrollView.
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Jagadeesh Gowda'), findsOneWidget);
      expect(find.text('jagadeesh@mechaconnect.ai'), findsOneWidget);
      expect(find.text('Pro Member'), findsOneWidget);
      expect(find.text('My Vehicles'), findsOneWidget);
      expect(find.text('Wallet'), findsOneWidget);
      expect(find.text('Orders'), findsWidgets);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('loading state renders before data arrives', (tester) async {
      final repository = ProfileRepository(
        latency: const Duration(milliseconds: 50),
        notificationSettingsStore: InMemoryNotificationSettingsStore(),
      );
      await tester.pumpWidget(_wrap(
        const ProfileScreen(),
        provider: ProfileProvider(repository: repository),
      ));
      await tester.pump();

      // Still loading: skeleton is on screen, account content is not.
      expect(find.text('Jagadeesh Gowda'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('Jagadeesh Gowda'), findsOneWidget);
    });

    testWidgets('error state offers a retry that recovers', (tester) async {
      await tester.pumpWidget(_wrap(
        const ProfileScreen(),
        provider: ProfileProvider(
          repository: _fastRepo(failForFirstCalls: 1),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Jagadeesh Gowda'), findsOneWidget);
    });

    testWidgets('edit button opens the edit profile screen', (tester) async {
      await tester.pumpWidget(_wrap(const ProfileScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Edit profile'));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
    });
  });

  group('MyVehiclesScreen', () {
    testWidgets('renders seeded vehicles', (tester) async {
      final provider = ProfileProvider(repository: _fastRepo());
      // runAsync so the repo's simulated-latency timer runs for real — awaiting
      // it directly inside testWidgets would deadlock the fake-async clock.
      await tester.runAsync(provider.loadHome);

      await tester.pumpWidget(_wrap(const MyVehiclesScreen(), provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Honda Activa 6G'), findsOneWidget);
      expect(find.text('Maruti Swift'), findsOneWidget);
    });

    testWidgets('shows the empty state when no vehicles exist', (tester) async {
      final provider = ProfileProvider(repository: _fastRepo());
      await tester.runAsync(() async {
        await provider.loadHome();
        await provider.deleteVehicle('veh-101');
        await provider.deleteVehicle('veh-102');
      });

      await tester.pumpWidget(_wrap(const MyVehiclesScreen(), provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('No vehicles yet'), findsOneWidget);
    });

    testWidgets('add-vehicle sheet saves a new vehicle', (tester) async {
      final provider = ProfileProvider(repository: _fastRepo());
      await tester.runAsync(provider.loadHome);

      await tester.pumpWidget(_wrap(const MyVehiclesScreen(), provider: provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Vehicle'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Brand'), 'TVS');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Model'), 'Apache RTR');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Registration number'),
          'KA 03 EF 9999');

      final submit = find.widgetWithText(ElevatedButton, 'Add Vehicle');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(provider.vehicles.length, 3);
      expect(find.text('TVS Apache RTR'), findsOneWidget);

      // Let the "Vehicle added" SnackBar timer elapse before the test ends.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('SavedAddressesScreen', () {
    testWidgets('renders seeded addresses', (tester) async {
      final provider = ProfileProvider(repository: _fastRepo());
      await tester.runAsync(provider.loadHome);

      await tester.pumpWidget(_wrap(const SavedAddressesScreen(), provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsWidgets);
      expect(find.textContaining('Surampalem'), findsOneWidget);
    });

    testWidgets('add-address sheet saves a new address', (tester) async {
      final provider = ProfileProvider(repository: _fastRepo());
      await tester.runAsync(provider.loadHome);

      await tester.pumpWidget(
          _wrap(const SavedAddressesScreen(), provider: provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Address'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address'),
        '2nd Floor, Tech Park, Hyderabad',
      );

      final submit = find.widgetWithText(ElevatedButton, 'Add Address');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(provider.addresses.length, 3);
      expect(find.textContaining('Hyderabad'), findsOneWidget);

      // Let the "Address added" SnackBar timer elapse before the test ends.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('profileAvatarIcon', () {
    test('maps avatar keys to icons with a person fallback', () {
      expect(profileAvatarIcon('avatar-bike'), Icons.two_wheeler_rounded);
      expect(profileAvatarIcon('avatar-car'), Icons.directions_car_rounded);
      expect(profileAvatarIcon(null), Icons.person_rounded);
      expect(profileAvatarIcon('unknown'), Icons.person_rounded);
    });
  });
}
