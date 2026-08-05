import 'package:flutter/foundation.dart';

/// Pure validation rules for every Profile form field.
///
/// ALL form validation in the Profile module lives here (never inside widgets)
/// so the rules are unit-testable and reusable across screens.
class ValidationService {
  const ValidationService._();

  static final RegExp _emailPattern =
      RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final RegExp _phonePattern = RegExp(r'^(\+91[\s-]?)?\d{10}$');
  static final RegExp _registrationPattern =
      RegExp(r'^[A-Z]{2}[\s-]?\d{2}[\s-]?[A-Z]{1,2}[\s-]?\d{1,4}$');

  /// Returns an error message or null when [value] is valid.
  static String? fullName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your full name';
    if (trimmed.length < 2) return 'Name must be at least 2 characters';
    if (trimmed.length > 50) return 'Name must be under 50 characters';
    return null;
  }

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your phone number';
    if (!_phonePattern.hasMatch(trimmed.replaceAll(' ', ''))) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? dateOfBirth(DateTime? value) {
    if (value == null) return 'Select your date of birth';
    if (value.isAfter(DateTime.now())) return 'Date of birth cannot be in the future';
    return null;
  }

  static String? gender(String? value) {
    if (value == null || value.trim().isEmpty) return 'Select a gender';
    return null;
  }

  static String? registration(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    if (normalized.isEmpty) return 'Enter the registration number';
    if (!_registrationPattern.hasMatch(normalized)) {
      return 'Enter a valid registration (e.g. KA 01 AB 1234)';
    }
    return null;
  }

  static String? vehicleBrand(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Enter the brand';
    return null;
  }

  static String? vehicleModel(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Enter the model';
    return null;
  }

  static String? address(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter the address';
    if (trimmed.length < 8) return 'Address is too short';
    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').isEmpty) return 'Enter your current password';
    return null;
  }

  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a new password';
    if (v.length < 6) return 'Use at least 6 characters';
    return null;
  }

  static String? confirmNewPassword(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Confirm your new password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  /// Always non-null when debugging asserts on the live validator.
  @visibleForTesting
  static String? debugEmail(String? value) => email(value);
}
