import 'package:flutter/foundation.dart';
import 'package:mecha_connect/features/auth/widgets/password_strength.dart';
import 'package:mecha_connect/features/auth/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;
  bool _rememberMe = false;
  String? _savedEmail;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get rememberMe => _rememberMe;
  String? get savedEmail => _savedEmail;

  AuthProvider(this._authService) {
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool('remember_me') ?? false;
    if (_rememberMe) {
      _savedEmail = prefs.getString('remember_me_email');
    }
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    notifyListeners();
  }

  String? validateEmail(String? value) => _authService.validateEmail(value);
  String? validateName(String? value) => _authService.validateName(value);
  String? validatePhone(String? value) => _authService.validatePhone(value);
  String? validatePassword(String? value) => _authService.validatePassword(value);
  String? validateConfirmPassword(String? value, String password) =>
      _authService.validateConfirmPassword(value, password);

  PasswordStrength evaluatePasswordStrength(String password) =>
      _authService.evaluatePasswordStrength(password);

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.login(email, password);
      if (success) {
        _isLoggedIn = true;
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('remember_me_email', email);
        } else {
          await prefs.remove('remember_me_email');
          await prefs.remove('remember_me_password');
        }
        await prefs.setBool('remember_me', _rememberMe);
        await prefs.setBool('is_logged_in', true);
        await prefs.setBool('onboarding_completed', true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<void> forgotPassword(String email) async {
    await _authService.forgotPassword(email);
  }

  Future<bool> register(String name, String email, String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.register(name, email, phone, password);
      if (success) {
        _isLoggedIn = true;
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('remember_me_email', email);
        } else {
          await prefs.remove('remember_me_email');
          await prefs.remove('remember_me_password');
        }
        await prefs.setBool('remember_me', _rememberMe);
        await prefs.setBool('is_logged_in', true);
        await prefs.setBool('onboarding_completed', true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('remember_me_email');
    await prefs.remove('remember_me_password');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
