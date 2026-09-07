import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/parts/order_data.dart';
import 'package:mecha_connect/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thrown by the Profile backend when it encounters a network or service failure.
class ProfileNetworkException implements Exception {
  final String message;
  const ProfileNetworkException([this.message = '']);

  @override
  String toString() => message.isNotEmpty
      ? message
      : 'Profile service is temporarily unreachable. Please try again.';
}

/// Persistence contract for [NotificationSettings].
abstract class NotificationSettingsStore {
  Future<NotificationSettings> load();
  Future<void> save(NotificationSettings settings);
}

/// SharedPreferences-backed store (production).
class SharedPreferencesNotificationSettingsStore
    implements NotificationSettingsStore {
  static const _key = 'profile_notification_settings';

  @override
  Future<NotificationSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return const NotificationSettings();
      return NotificationSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const NotificationSettings();
    }
  }

  @override
  Future<void> save(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}

/// In-memory store (tests and default when none is injected).
class InMemoryNotificationSettingsStore implements NotificationSettingsStore {
  NotificationSettings _settings = const NotificationSettings();

  @override
  Future<NotificationSettings> load() async => _settings;

  @override
  Future<void> save(NotificationSettings settings) async {
    _settings = settings;
  }
}

/// User Profile Repository connecting with FastAPI `/api/v1/users/me`.
class ProfileRepository {
  static const Duration defaultLatency = Duration(milliseconds: 800);

  final Duration latency;
  final int failForFirstCalls;
  final NotificationSettingsStore _notificationStore;
  final ApiClient? _apiClient;

  UserProfile _profile = _seedProfile();
  List<ProfileVehicle> _vehicles = [];
  List<SavedAddress> _addresses = [];
  int _vehicleCounter = 200;
  int _addressCounter = 200;
  int _callCount = 0;

  ProfileRepository({
    this.latency = defaultLatency,
    this.failForFirstCalls = 0,
    NotificationSettingsStore? notificationSettingsStore,
    ApiClient? apiClient,
  })  : _notificationStore =
            notificationSettingsStore ?? InMemoryNotificationSettingsStore(),
        _apiClient = apiClient {
    _seed();
  }

  // ── Failure + latency simulation ───────────────────────────────────────

  Future<T> _call<T>(FutureOr<T> Function() body) async {
    if (_apiClient == null) {
      await Future<void>.delayed(latency);
      if (failForFirstCalls > 0 && _callCount < failForFirstCalls) {
        _callCount++;
        throw const ProfileNetworkException(
          'Could not reach the profile service. Check your connection and retry.',
        );
      }
      _callCount++;
    }
    return await body();
  }

  // ── Seed data ──────────────────────────────────────────────────────────

  void _seed() {
    if (_apiClient == null) {
      _profile = _seedProfile();
      final now = DateTime.now();
      _vehicles = [
        ProfileVehicle(
          id: 'veh-101',
          brand: 'Honda',
          model: 'Activa 6G',
          registration: 'KA 01 AB 1234',
          fuelType: VehicleFuel.petrol,
          insuranceExpiry: DateTime(now.year + 1, 3, 1),
          pucExpiry: DateTime(now.year, 12, 31),
          serviceDueKm: 1500,
          serviceDueDate: now.add(const Duration(days: 21)),
          isDefault: true,
          healthScore: 92,
        ),
        ProfileVehicle(
          id: 'veh-102',
          brand: 'Maruti',
          model: 'Swift',
          registration: 'KA 02 CD 5678',
          fuelType: VehicleFuel.diesel,
          insuranceExpiry: DateTime(now.year, 6, 15),
          pucExpiry: DateTime(now.year, 8, 20),
          serviceDueKm: 800,
          healthScore: 78,
        ),
      ];
    } else {
      _profile = UserProfile(
        name: '',
        email: '',
        phone: '',
        joinedDate: DateTime.now(),
        membershipTier: MembershipTier.free,
      );
      _vehicles = [];
      _addresses = [];
    }
    if (_apiClient == null) {
      _addresses = [
        const SavedAddress(
          id: 'addr-101',
          label: AddressLabel.home,
          address: '12-3-45, Main Road, Surampalem, Andhra Pradesh 533437',
          latitude: 17.1078,
          longitude: 81.7961,
          isDefault: true,
        ),
        const SavedAddress(
          id: 'addr-102',
          label: AddressLabel.office,
          address: '1 MG Road, Indiranagar, Bengaluru 560038',
          latitude: 12.9716,
          longitude: 77.5946,
        ),
      ];
    }
  }

  static UserProfile _seedProfile() {
    return UserProfile(
      name: 'Jagadeesh Gowda',
      email: 'jagadeesh@mechaconnect.ai',
      phone: '+91 98765 43210',
      dateOfBirth: DateTime(1995, 4, 12),
      gender: 'Male',
      joinedDate: DateTime(2025, 1, 15),
      membershipTier: MembershipTier.pro,
      emergencyContact: const EmergencyContact(
        name: 'Priya Gowda',
        relation: 'Sister',
        phone: '+91 98765 43219',
      ),
    );
  }

  // ── API / Data methods ──────────────────────────────────────────────────

  Future<UserProfile> fetchProfile() => _call(() async {
    if (_apiClient != null) {
      final res = await _apiClient.get(
        '/api/v1/users/me',
        requiresAuth: true,
      );
      if (res is Map<String, dynamic>) {
        _profile = UserProfile.fromJson(res);
        return _profile;
      }
    }
    return _profile;
  });

  Future<UserProfile> saveProfile(UserProfile profile) => _call(() async {
    if (_apiClient != null) {
      final res = await _apiClient.patch(
        '/api/v1/users/me',
        body: profile.toUpdateJson(),
        requiresAuth: true,
      );
      if (res is Map<String, dynamic>) {
        _profile = UserProfile.fromJson(res);
        return _profile;
      }
    }
    _profile = profile;
    return _profile;
  });

  Future<List<ProfileVehicle>> fetchVehicles() => _call(() async {
    if (_apiClient != null) {
      final res = await _apiClient.get(
        '/api/v1/vehicles',
        requiresAuth: true,
      );
      if (res is List) {
        _vehicles = res
            .map((e) => ProfileVehicle.fromJson(e as Map<String, dynamic>))
            .toList();
        return List.unmodifiable(_sortedVehicles());
      }
    }
    return List.unmodifiable(_sortedVehicles());
  });

  List<ProfileVehicle> _sortedVehicles() {
    final sorted = [..._vehicles]..sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return a.brand.compareTo(b.brand);
      });
    return sorted;
  }

  Future<List<ProfileVehicle>> saveVehicle(ProfileVehicle vehicle) => _call(() async {
    if (_apiClient != null) {
      await _apiClient.patch(
        '/api/v1/vehicles/${vehicle.id}',
        body: vehicle.toUpdateJson(),
        requiresAuth: true,
      );
      return fetchVehicles();
    }
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index >= 0) {
      _vehicles[index] = vehicle;
    } else {
      _vehicles.add(vehicle);
    }
    if (vehicle.isDefault) _promoteDefaultVehicle(vehicle.id);
    return List.unmodifiable(_sortedVehicles());
  });

  Future<List<ProfileVehicle>> addVehicle(ProfileVehicle vehicle) => _call(() async {
    if (_apiClient != null) {
      await _apiClient.post(
        '/api/v1/vehicles',
        body: vehicle.toCreateJson(),
        requiresAuth: true,
      );
      return fetchVehicles();
    }
    _vehicleCounter++;
    final created = vehicle.id.isEmpty
        ? vehicle.copyWith(id: 'veh-$_vehicleCounter')
        : vehicle;
    _vehicles.add(created);
    if (created.isDefault) _promoteDefaultVehicle(created.id);
    return List.unmodifiable(_sortedVehicles());
  });

  Future<List<ProfileVehicle>> deleteVehicle(String id) => _call(() async {
    if (_apiClient != null) {
      await _apiClient.delete('/api/v1/vehicles/$id', requiresAuth: true);
      return fetchVehicles();
    }
    _vehicles.removeWhere((v) => v.id == id);
    if (_vehicles.isNotEmpty && !_vehicles.any((v) => v.isDefault)) {
      _vehicles[0] = _vehicles[0].copyWith(isDefault: true);
    }
    return List.unmodifiable(_sortedVehicles());
  });

  Future<List<ProfileVehicle>> setDefaultVehicle(String id) => _call(() async {
    if (_apiClient != null) {
      await _apiClient.post('/api/v1/vehicles/$id/default', requiresAuth: true);
      return fetchVehicles();
    }
    _promoteDefaultVehicle(id);
    return List.unmodifiable(_sortedVehicles());
  });

  void _promoteDefaultVehicle(String id) {
    _vehicles = [
      for (final v in _vehicles) v.copyWith(isDefault: v.id == id),
    ];
  }

  Future<List<SavedAddress>> fetchAddresses() => _call(() async {
    if (_apiClient != null) {
      final res = await _apiClient.get('/api/v1/addresses', requiresAuth: true);
      if (res is List) {
        _addresses = res
            .map((e) => SavedAddress.fromJson(e as Map<String, dynamic>))
            .toList();
        return List.unmodifiable(_sortedAddresses());
      }
    }
    return List.unmodifiable(_sortedAddresses());
  });

  List<SavedAddress> _sortedAddresses() {
    final sorted = [..._addresses]..sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return a.label.index.compareTo(b.label.index);
      });
    return sorted;
  }

  Future<List<SavedAddress>> addAddress(SavedAddress address) => _call(() async {
    if (_apiClient != null) {
      await _apiClient.post(
        '/api/v1/addresses',
        body: address.toCreateJson(),
        requiresAuth: true,
      );
      return fetchAddresses();
    }
    _addressCounter++;
    final created = address.id.isEmpty
        ? address.copyWith(id: 'addr-$_addressCounter')
        : address;
    _addresses.add(created);
    if (created.isDefault) _promoteDefaultAddress(created.id);
    return List.unmodifiable(_sortedAddresses());
  });

  Future<List<SavedAddress>> saveAddress(SavedAddress address) => _call(() async {
    if (_apiClient != null) {
      await _apiClient.patch(
        '/api/v1/addresses/${address.id}',
        body: address.toUpdateJson(),
        requiresAuth: true,
      );
      return fetchAddresses();
    }
    final index = _addresses.indexWhere((a) => a.id == address.id);
    if (index >= 0) {
      _addresses[index] = address;
    } else {
      _addressCounter++;
      _addresses.add(
        address.id.isEmpty
            ? address.copyWith(id: 'addr-$_addressCounter')
            : address,
      );
    }
    if (address.isDefault) _promoteDefaultAddress(address.id);
    return List.unmodifiable(_sortedAddresses());
  });

  Future<List<SavedAddress>> deleteAddress(String id) => _call(() async {
    if (_apiClient != null) {
      await _apiClient.delete('/api/v1/addresses/$id', requiresAuth: true);
      return fetchAddresses();
    }
    _addresses.removeWhere((a) => a.id == id);
    if (_addresses.isNotEmpty && !_addresses.any((a) => a.isDefault)) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }
    return List.unmodifiable(_sortedAddresses());
  });

  Future<List<SavedAddress>> setDefaultAddress(String id) => _call(() async {
    if (_apiClient != null) {
      await _apiClient.post('/api/v1/addresses/$id/default', requiresAuth: true);
      return fetchAddresses();
    }
    _promoteDefaultAddress(id);
    return List.unmodifiable(_sortedAddresses());
  });

  void _promoteDefaultAddress(String id) {
    _addresses = [
      for (final a in _addresses) a.copyWith(isDefault: a.id == id),
    ];
  }

  Future<WalletData> fetchWallet() => _call(() async {
    if (_apiClient != null) {
      final res = await _apiClient.get('/api/v1/wallet', requiresAuth: true);
      if (res is Map<String, dynamic>) {
        final balance = (res['balance'] as num?)?.toDouble() ?? 0.0;
        final rewardPoints = (res['reward_points'] as num?)?.toInt() ?? 0;
        final rawTxns = res['transactions'] as List? ?? [];
        final txns = rawTxns
            .map((t) => WalletTransaction.fromJson(t as Map<String, dynamic>))
            .toList();

        return WalletData(
          balance: balance,
          rewardPoints: rewardPoints,
          transactions: txns,
          coupons: const [],
          paymentMethods: const [],
        );
      }
    }
    return WalletData(
      balance: 1200,
      rewardPoints: 2450,
      transactions: [
        const WalletTransaction(
          id: 'txn-101',
          title: 'Fuel Delivery',
          subtitle: 'Indian Oil · 5L Petrol',
          amount: 500,
          type: WalletTransactionType.debit,
          date: 'Today',
          icon: Icons.local_gas_station_rounded,
        ),
        const WalletTransaction(
          id: 'txn-102',
          title: 'Recharge',
          subtitle: 'UPI added ₹1,000',
          amount: 1000,
          type: WalletTransactionType.credit,
          date: 'Yesterday',
          icon: Icons.account_balance_wallet_rounded,
        ),
        const WalletTransaction(
          id: 'txn-103',
          title: 'Cashback',
          subtitle: 'Service reward',
          amount: 150,
          type: WalletTransactionType.credit,
          date: '2 days ago',
          icon: Icons.card_giftcard_rounded,
        ),
        const WalletTransaction(
          id: 'txn-104',
          title: 'Brake Pads',
          subtitle: 'Marketplace order',
          amount: 699,
          type: WalletTransactionType.debit,
          date: '3 days ago',
          icon: Icons.inventory_2_rounded,
        ),
      ],
      coupons: const [
        Coupon(
          code: 'FUEL10',
          title: '₹10 off per litre on fuel delivery',
          discount: '10%',
          validUntil: 'Valid till 30 Sep',
        ),
        Coupon(
          code: 'SERVE50',
          title: 'Flat ₹50 off on mechanic service',
          discount: '₹50',
          validUntil: 'Valid till 15 Oct',
        ),
      ],
      paymentMethods: const [
        PaymentMethod(
          id: 'pay-101',
          name: 'UPI',
          details: 'jagadeesh@okhdfcbank',
          icon: Icons.qr_code_2_rounded,
        ),
        PaymentMethod(
          id: 'pay-102',
          name: 'Credit Card',
          details: 'HDFC ·•· 4242',
          icon: Icons.credit_card_rounded,
        ),
      ],
    );
  });

  Future<RewardsData> fetchRewards() => _call(() async {
    if (_apiClient != null) {
      final res = await _apiClient.get('/api/v1/rewards', requiresAuth: true);
      if (res is Map<String, dynamic>) {
        final redeemable = (res['redeemable_points'] as num?)?.toInt() ?? 0;
        final totalEarned = (res['total_earned'] as num?)?.toInt() ?? redeemable;
        final rawLedger = res['ledger'] as List? ?? [];
        final rewards = rawLedger
            .map((r) => Reward.fromJson(r as Map<String, dynamic>))
            .toList();

        return RewardsData(
          redeemablePoints: redeemable,
          totalEarned: totalEarned,
          rewards: rewards,
          achievements: const [],
          referralCode: '',
          referralRewardPoints: 200,
          tierProgress: RewardTierProgress(
            currentTier: _profile.membershipTier,
            nextTier: MembershipTier.pro,
            currentPoints: redeemable,
            pointsToNext: 500,
            benefits: const [
              'Priority mechanic dispatch',
              'Free AI diagnostics',
            ],
          ),
        );
      }
    }
    return RewardsData(
      redeemablePoints: 2450,
      totalEarned: 3200,
      rewards: [
        const Reward(
          id: 'rew-101',
          title: 'Service completed',
          subtitle: 'Honda Activa 6G — oil change',
          points: 150,
          type: RewardType.earned,
          date: 'Today',
          icon: Icons.build_rounded,
        ),
        const Reward(
          id: 'rew-102',
          title: 'Referred a friend',
          subtitle: 'Vikram joined with your code',
          points: 200,
          type: RewardType.referral,
          date: 'Yesterday',
          icon: Icons.person_add_rounded,
        ),
        const Reward(
          id: 'rew-103',
          title: 'Redeemed wallet credit',
          subtitle: '₹50 off on fuel delivery',
          points: 500,
          type: RewardType.redeemed,
          date: '4 days ago',
          icon: Icons.redeem_rounded,
        ),
        const Reward(
          id: 'rew-104',
          title: 'First ride milestone',
          subtitle: 'Completed 5 deliveries',
          points: 300,
          type: RewardType.achievement,
          date: 'Last week',
          icon: Icons.emoji_events_rounded,
        ),
      ],
      achievements: const [
        '5 deliveries completed',
        'First service booked',
        'AI diagnosis pioneer',
        'Eco rider',
      ],
      referralCode: 'GOWDA200',
      referralRewardPoints: 200,
      tierProgress: const RewardTierProgress(
        currentTier: MembershipTier.pro,
        nextTier: MembershipTier.free,
        currentPoints: 2450,
        pointsToNext: 550,
        benefits: [
          'Priority mechanic dispatch',
          'Free AI diagnostics',
          '5% cashback on every order',
        ],
      ),
    );
  });

  Future<ProfileStats> fetchStats() => _call(() async {
    int rewardsCount = 0;
    if (_apiClient != null) {
      try {
        final rew = await fetchRewards();
        rewardsCount = rew.redeemablePoints;
      } catch (_) {}
    } else {
      rewardsCount = 2450;
    }
    return ProfileStats(
      vehicles: _vehicles.length,
      services: 0,
      orders: ordersList.length,
      rewards: rewardsCount,
    );
  });

  Future<List<Map<String, dynamic>>> fetchOrders() => _call(() async {
    if (_apiClient != null) {
      try {
        final res = await _apiClient.get('/api/v1/orders', requiresAuth: true);
        if (res is List) {
          final list = <Map<String, dynamic>>[];
          for (final o in res) {
            if (o is Map<String, dynamic>) {
              list.add({
                'id': o['id'] ?? '',
                'name': o['name'] ?? 'Order',
                'brand': o['brand'] ?? '',
                'quantity': o['quantity'] ?? 1,
                'price': (o['price'] as num?)?.toDouble() ?? 0.0,
                'image': o['image'],
                'type': o['type'] ?? 'parts',
                'status': o['status'] ?? 'Pending',
                'date': o['occurred_at'] != null
                    ? o['occurred_at'].toString().split('T').first
                    : 'Recent',
              });
            }
          }
          return list;
        }
      } catch (e) {
        debugPrint('ProfileRepository.fetchOrders backend fetch error: $e');
      }
    }
    return List.unmodifiable(
      ordersList.map((o) => Map<String, dynamic>.of(o)).toList(),
    );
  });

  Future<NotificationSettings> fetchNotificationSettings() => _call(() async {
    final local = await _notificationStore.load();
    if (_apiClient != null) {
      try {
        final res = await _apiClient.get(
          '/api/v1/notification-settings',
          requiresAuth: true,
        );
        if (res is Map<String, dynamic> && res['push'] is bool) {
          final updated = local.copyWith(push: res['push'] as bool);
          await _notificationStore.save(updated);
          return updated;
        }
      } catch (_) {}
    }
    return local;
  });

  Future<NotificationSettings> saveNotificationSettings(
    NotificationSettings settings,
  ) => _call(() async {
    await _notificationStore.save(settings);
    if (_apiClient != null) {
      try {
        await _apiClient.patch(
          '/api/v1/notification-settings',
          body: {'push': settings.push},
          requiresAuth: true,
        );
      } catch (_) {}
    }
    return settings;
  });
}
