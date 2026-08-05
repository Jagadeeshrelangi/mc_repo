import 'package:flutter/foundation.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/features/profile/repositories/profile_repository.dart';
import 'package:mecha_connect/features/profile/services/profile_service.dart';

/// Overall screen state for Profile surfaces that load remote data.
enum ProfileScreenState { initial, loading, ready, error }

/// Single source of truth for the Profile / Account Center module.
///
/// Owns the user profile, vehicles, saved addresses, wallet, rewards, the
/// unified order history and notification settings. Everything is derived from
/// exactly one in-memory store — nothing mirrors or re-fetches it — so the
/// profile home, sub-screens and the Orders tab can never disagree.
class ProfileProvider extends ChangeNotifier {
  final ProfileService _service;

  ProfileProvider({ProfileRepository? repository, ProfileService? service})
      : _service = service ?? ProfileService(repository: repository);

  // ── Home state ─────────────────────────────────────────────────────────
  ProfileScreenState _state = ProfileScreenState.initial;
  ProfileScreenState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  // ── Account data ───────────────────────────────────────────────────────
  UserProfile? _profile;
  UserProfile? get profile => _profile;

  ProfileStats? _stats;
  ProfileStats? get stats => _stats;

  List<ProfileVehicle> _vehicles = [];
  List<ProfileVehicle> get vehicles => List.unmodifiable(_vehicles);

  ProfileVehicle? get defaultVehicle {
    for (final v in _vehicles) {
      if (v.isDefault) return v;
    }
    return _vehicles.isEmpty ? null : _vehicles.first;
  }

  List<SavedAddress> _addresses = [];
  List<SavedAddress> get addresses => List.unmodifiable(_addresses);

  WalletData? _wallet;
  WalletData? get wallet => _wallet;

  RewardsData? _rewards;
  RewardsData? get rewards => _rewards;

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> get orders => List.unmodifiable(_orders);

  NotificationSettings _notificationSettings = const NotificationSettings();
  NotificationSettings get notificationSettings => _notificationSettings;

  // ── Operation flags / errors ───────────────────────────────────────────
  bool _isSavingProfile = false;
  bool get isSavingProfile => _isSavingProfile;

  bool _isSavingVehicle = false;
  bool get isSavingVehicle => _isSavingVehicle;

  bool _isSavingAddress = false;
  bool get isSavingAddress => _isSavingAddress;

  String? _operationError;
  String? get operationError => _operationError;

  // ── Home load ──────────────────────────────────────────────────────────

  Future<void> loadHome() async {
    if (_state == ProfileScreenState.loading) return;
    _state = ProfileScreenState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        _service.loadProfile(),
        _service.loadVehicles(),
        _service.loadAddresses(),
        _service.loadWallet(),
        _service.loadRewards(),
        _service.loadStats(),
        _service.loadOrders(),
        _service.loadNotificationSettings(),
      ]);
      _profile = results[0] as UserProfile;
      _vehicles = [...results[1] as List<ProfileVehicle>];
      _addresses = [...results[2] as List<SavedAddress>];
      _wallet = results[3] as WalletData;
      _rewards = results[4] as RewardsData;
      _stats = results[5] as ProfileStats;
      _orders = [
        for (final o in results[6] as List<Map<String, dynamic>>)
          Map<String, dynamic>.of(o),
      ];
      _notificationSettings = results[7] as NotificationSettings;
      _state = ProfileScreenState.ready;
    } catch (e) {
      _state = ProfileScreenState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> refreshHome() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _service.loadProfile(),
        _service.loadVehicles(),
        _service.loadAddresses(),
        _service.loadWallet(),
        _service.loadRewards(),
        _service.loadStats(),
        _service.loadOrders(),
        _service.loadNotificationSettings(),
      ]);
      _profile = results[0] as UserProfile;
      _vehicles = [...results[1] as List<ProfileVehicle>];
      _addresses = [...results[2] as List<SavedAddress>];
      _wallet = results[3] as WalletData;
      _rewards = results[4] as RewardsData;
      _stats = results[5] as ProfileStats;
      _orders = [
        for (final o in results[6] as List<Map<String, dynamic>>)
          Map<String, dynamic>.of(o),
      ];
      _notificationSettings = results[7] as NotificationSettings;
    } catch (_) {
      // Pull-to-refresh failures keep the loaded data on screen.
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // ── Profile ────────────────────────────────────────────────────────────

  Future<bool> updateProfile(UserProfile draft) async {
    return _runProfileOperation(() async {
      _profile = await _service.saveProfile(draft);
    });
  }

  // ── Vehicles ───────────────────────────────────────────────────────────

  Future<bool> addVehicle(ProfileVehicle vehicle) async {
    return _runVehicleOperation(() async {
      _vehicles = await _service.addVehicle(vehicle);
    });
  }

  Future<bool> saveVehicle(ProfileVehicle vehicle) async {
    return _runVehicleOperation(() async {
      _vehicles = await _service.saveVehicle(vehicle);
    });
  }

  Future<bool> deleteVehicle(String id) async {
    return _runVehicleOperation(() async {
      _vehicles = await _service.deleteVehicle(id);
    });
  }

  Future<bool> setDefaultVehicle(String id) async {
    return _runVehicleOperation(() async {
      _vehicles = await _service.setDefaultVehicle(id);
    });
  }

  // ── Addresses ──────────────────────────────────────────────────────────

  Future<bool> addAddress(SavedAddress address) async {
    return _runAddressOperation(() async {
      _addresses = await _service.addAddress(address);
    });
  }

  Future<bool> saveAddress(SavedAddress address) async {
    return _runAddressOperation(() async {
      _addresses = await _service.saveAddress(address);
    });
  }

  Future<bool> deleteAddress(String id) async {
    return _runAddressOperation(() async {
      _addresses = await _service.deleteAddress(id);
    });
  }

  Future<bool> setDefaultAddress(String id) async {
    return _runAddressOperation(() async {
      _addresses = await _service.setDefaultAddress(id);
    });
  }

  // ── Notification settings ──────────────────────────────────────────────

  Future<bool> saveNotificationSettings(NotificationSettings settings) async {
    _operationError = null;
    notifyListeners();
    try {
      _notificationSettings =
          await _service.saveNotificationSettings(settings);
      notifyListeners();
      return true;
    } catch (e) {
      _operationError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Validation (single home: ProfileService) ───────────────────────────

  String? validateFullName(String? value) => _service.validateFullName(value);
  String? validateEmail(String? value) => _service.validateEmail(value);
  String? validatePhone(String? value) => _service.validatePhone(value);
  String? validateDateOfBirth(DateTime? value) =>
      _service.validateDateOfBirth(value);
  String? validateGender(String? value) => _service.validateGender(value);
  String? validateRegistration(String? value) =>
      _service.validateRegistration(value);
  String? validateVehicleBrand(String? value) =>
      _service.validateVehicleBrand(value);
  String? validateVehicleModel(String? value) =>
      _service.validateVehicleModel(value);
  String? validateAddress(String? value) => _service.validateAddress(value);
  String? validatePassword(String? value) => _service.validatePassword(value);
  String? validateNewPassword(String? value) =>
      _service.validateNewPassword(value);
  String? validateConfirmNewPassword(String? value, String password) =>
      _service.validateConfirmNewPassword(value, password);

  String? validateProfileForm({
    required String name,
    required String email,
    required String phone,
    DateTime? dateOfBirth,
    String? gender,
    EmergencyContact? emergencyContact,
  }) =>
      _service.validateProfileForm(
        name: name,
        email: email,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
        emergencyContact: emergencyContact,
      );

  // ── Private helpers ────────────────────────────────────────────────────

  Future<bool> _runProfileOperation(Future<void> Function() action) async {
    _operationError = null;
    _isSavingProfile = true;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _operationError = e.toString();
      return false;
    } finally {
      _isSavingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> _runVehicleOperation(Future<void> Function() action) async {
    _operationError = null;
    _isSavingVehicle = true;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _operationError = e.toString();
      return false;
    } finally {
      _isSavingVehicle = false;
      notifyListeners();
    }
  }

  Future<bool> _runAddressOperation(Future<void> Function() action) async {
    _operationError = null;
    _isSavingAddress = true;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _operationError = e.toString();
      return false;
    } finally {
      _isSavingAddress = false;
      notifyListeners();
    }
  }
}
