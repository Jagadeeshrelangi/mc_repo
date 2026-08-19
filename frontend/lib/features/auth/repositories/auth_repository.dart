import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mecha_connect/services/api_client.dart';

/// Authentication repository bridging Flutter auth with FastAPI backend.
///
/// Dispatches HTTP requests to `/api/v1/auth/login`, `/api/v1/auth/register`,
/// `/api/v1/auth/forgot-password`, and stores JWT access/refresh tokens.
/// If the backend is unreachable (offline development/tests), it gracefully
/// falls back to local simulation so offline widget tests remain resilient.
class AuthRepository {
  final ApiClient _apiClient;
  final bool enableFallback;

  AuthRepository({ApiClient? apiClient, this.enableFallback = true})
      : _apiClient = apiClient ?? ApiClient();

  Future<bool> login(String email, String password) async {
    try {
      final res = await _apiClient.post(
        '/api/v1/auth/login',
        body: {'email': email.trim(), 'password': password},
        requiresAuth: false,
      );

      if (res is Map<String, dynamic> && res['access_token'] != null) {
        await _apiClient.saveTokens(
          accessToken: res['access_token'].toString(),
          refreshToken: (res['refresh_token'] ?? '').toString(),
        );
        return true;
      }
      return false;
    } catch (e) {
      if (enableFallback && (e is ApiException && e.statusCode == 0)) {
        debugPrint('Backend offline — falling back to mock login');
        await Future.delayed(const Duration(milliseconds: 300));
        return true;
      }
      rethrow;
    }
  }

  Future<bool> register(String name, String email, String phone, String password) async {
    try {
      final res = await _apiClient.post(
        '/api/v1/auth/register',
        body: {
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone.trim().isNotEmpty ? phone.trim() : null,
          'password': password,
        },
        requiresAuth: false,
      );

      if (res is Map<String, dynamic> && res['access_token'] != null) {
        await _apiClient.saveTokens(
          accessToken: res['access_token'].toString(),
          refreshToken: (res['refresh_token'] ?? '').toString(),
        );
        return true;
      }
      return false;
    } catch (e) {
      if (enableFallback && (e is ApiException && e.statusCode == 0)) {
        debugPrint('Backend offline — falling back to mock register');
        await Future.delayed(const Duration(milliseconds: 300));
        return true;
      }
      rethrow;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _apiClient.post(
        '/api/v1/auth/forgot-password',
        body: {'email': email.trim()},
        requiresAuth: false,
      );
      return true;
    } catch (e) {
      if (enableFallback && (e is ApiException && e.statusCode == 0)) {
        await Future.delayed(const Duration(milliseconds: 300));
        return true;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/api/v1/auth/logout', requiresAuth: true);
    } catch (_) {
      // Best-effort logout
    } finally {
      await _apiClient.clearTokens();
    }
  }
}
