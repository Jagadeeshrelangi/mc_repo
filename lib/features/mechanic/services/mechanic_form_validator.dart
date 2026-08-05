/// Single source of truth for vehicle form validation.
///
/// Keeps the vehicle form free of duplicated validation logic and produces
/// user-friendly, consistent error messages used by the UI.
class MechanicFormValidator {
  static final RegExp _registrationPattern = RegExp(
    r'^[A-Z]{2}[ -]?[0-9]{1,2}[ -]?[A-Z]{1,3}[ -]?[0-9]{4}$',
  );

  static final RegExp _pincodePattern = RegExp(r'^[0-9]{6}$');

  static String? validateVehicleType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a vehicle type';
    }
    return null;
  }

  static String? validateBrand(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a brand';
    }
    return null;
  }

  static String? validateModel(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Please enter the vehicle model';
    }
    if (text.length < 2) {
      return 'Model name is too short';
    }
    return null;
  }

  static String? validateFuelType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a fuel type';
    }
    return null;
  }

  static String? validateRegistration(String? value) {
    final text = value?.trim().toUpperCase() ?? '';
    if (text.isEmpty) {
      return 'Please enter the registration number';
    }
    if (!_registrationPattern.hasMatch(text)) {
      return 'Enter a valid registration number e.g. KA 01 AB 1234';
    }
    return null;
  }

  static String? validateProblem(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Please describe the problem';
    }
    if (text.length < 10) {
      return 'Please describe the problem in more detail';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Please enter your address';
    }
    if (text.length < 8) {
      return 'Address is too short';
    }
    return null;
  }

  static String? validatePincode(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Please enter the pincode';
    }
    if (!_pincodePattern.hasMatch(text)) {
      return 'Enter a valid 6-digit pincode';
    }
    return null;
  }

  /// Returns the first validation error for the given values, or null if valid.
  static String? validateVehicleForm({
    String? vehicleType,
    String? brand,
    String? model,
    String? fuelType,
    String? registration,
    String? problem,
    String? address,
    String? pincode,
  }) {
    return validateVehicleType(vehicleType) ??
        validateBrand(brand) ??
        validateModel(model) ??
        validateFuelType(fuelType) ??
        validateRegistration(registration) ??
        validateProblem(problem) ??
        validateAddress(address) ??
        validatePincode(pincode);
  }

  static String normalizeRegistration(String value) {
    final compact = value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
    return compact.replaceAll(' ', ' ').replaceAll('-', ' ');
  }
}
