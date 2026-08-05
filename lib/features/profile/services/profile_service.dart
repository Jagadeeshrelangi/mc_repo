import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/features/profile/repositories/profile_repository.dart';
import 'package:mecha_connect/features/profile/services/validation_service.dart';

/// The application layer between [ProfileProvider] and [ProfileRepository].
///
/// Keeps transformation/mapping (and all validation) out of the screens and
/// the provider state machine. Sprint 2 only the repository internals change.
class ProfileService {
  final ProfileRepository _repository;

  ProfileService({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository();

  // ── Reads ──────────────────────────────────────────────────────────────

  Future<UserProfile> loadProfile() => _repository.fetchProfile();

  Future<List<ProfileVehicle>> loadVehicles() => _repository.fetchVehicles();

  Future<List<SavedAddress>> loadAddresses() => _repository.fetchAddresses();

  Future<WalletData> loadWallet() => _repository.fetchWallet();

  Future<RewardsData> loadRewards() => _repository.fetchRewards();

  Future<ProfileStats> loadStats() => _repository.fetchStats();

  Future<List<Map<String, dynamic>>> loadOrders() => _repository.fetchOrders();

  Future<NotificationSettings> loadNotificationSettings() =>
      _repository.fetchNotificationSettings();

  // ── Writes ─────────────────────────────────────────────────────────────

  Future<UserProfile> saveProfile(UserProfile profile) =>
      _repository.saveProfile(profile);

  Future<List<ProfileVehicle>> saveVehicle(ProfileVehicle vehicle) =>
      _repository.saveVehicle(vehicle);

  Future<List<ProfileVehicle>> addVehicle(ProfileVehicle vehicle) =>
      _repository.addVehicle(vehicle);

  Future<List<ProfileVehicle>> deleteVehicle(String id) =>
      _repository.deleteVehicle(id);

  Future<List<ProfileVehicle>> setDefaultVehicle(String id) =>
      _repository.setDefaultVehicle(id);

  Future<List<SavedAddress>> addAddress(SavedAddress address) =>
      _repository.addAddress(address);

  Future<List<SavedAddress>> saveAddress(SavedAddress address) =>
      _repository.saveAddress(address);

  Future<List<SavedAddress>> deleteAddress(String id) =>
      _repository.deleteAddress(id);

  Future<List<SavedAddress>> setDefaultAddress(String id) =>
      _repository.setDefaultAddress(id);

  Future<NotificationSettings> saveNotificationSettings(
    NotificationSettings settings,
  ) =>
      _repository.saveNotificationSettings(settings);

  // ── Validation (single home, never inside UI) ──────────────────────────

  String? validateFullName(String? value) => ValidationService.fullName(value);
  String? validateEmail(String? value) => ValidationService.email(value);
  String? validatePhone(String? value) => ValidationService.phone(value);
  String? validateDateOfBirth(DateTime? value) =>
      ValidationService.dateOfBirth(value);
  String? validateGender(String? value) => ValidationService.gender(value);
  String? validateRegistration(String? value) =>
      ValidationService.registration(value);
  String? validateVehicleBrand(String? value) =>
      ValidationService.vehicleBrand(value);
  String? validateVehicleModel(String? value) =>
      ValidationService.vehicleModel(value);
  String? validateAddress(String? value) => ValidationService.address(value);
  String? validatePassword(String? value) => ValidationService.password(value);
  String? validateNewPassword(String? value) =>
      ValidationService.newPassword(value);
  String? validateConfirmNewPassword(String? value, String password) =>
      ValidationService.confirmNewPassword(value, password);

  /// Validates the full edit-profile payload; returns the first error or null.
  String? validateProfileForm({
    required String name,
    required String email,
    required String phone,
    DateTime? dateOfBirth,
    String? gender,
    EmergencyContact? emergencyContact,
  }) {
    return validateFullName(name) ??
        validateEmail(email) ??
        validatePhone(phone) ??
        validateDateOfBirth(dateOfBirth) ??
        validateGender(gender) ??
        (emergencyContact != null &&
                (validateFullName(emergencyContact.name) != null ||
                    validatePhone(emergencyContact.phone) != null)
            ? 'Check the emergency contact details'
            : null);
  }
}
