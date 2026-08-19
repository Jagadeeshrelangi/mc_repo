import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Exception thrown when an API request returns a non-2xx status code or network failure.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;
  final dynamic details;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
    this.details,
  });

  @override
  String toString() => 'ApiException($statusCode): $message (Code: $errorCode)';
}

/// Centralized HTTP client managing authorization headers, token lifecycle,
/// and automated refresh retries for the FastAPI backend.
class ApiClient {
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';
  static const Duration defaultTimeout = Duration(seconds: 15);

  final String baseUrl;
  final http.Client _client;

  static ApiClient? _instance;

  factory ApiClient({String? baseUrl, http.Client? client}) {
    if (_instance == null || baseUrl != null || client != null) {
      _instance = ApiClient._internal(
        baseUrl: baseUrl ?? defaultBaseUrl,
        client: client ?? http.Client(),
      );
    }
    return _instance!;
  }

  ApiClient._internal({required this.baseUrl, required http.Client client})
      : _client = client;

  // ── Token Storage ──────────────────────────────────────────────────────────

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_access_token');
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_refresh_token');
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_access_token', accessToken);
    await prefs.setString('auth_refresh_token', refreshToken);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_access_token');
    await prefs.remove('auth_refresh_token');
  }

  // ── HTTP Request Dispatcher ────────────────────────────────────────────────

  Future<dynamic> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) =>
      _send('GET', path, headers: headers, queryParams: queryParams, requiresAuth: requiresAuth);

  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) =>
      _send('POST', path, body: body, headers: headers, queryParams: queryParams, requiresAuth: requiresAuth);

  Future<dynamic> patch(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) =>
      _send('PATCH', path, body: body, headers: headers, queryParams: queryParams, requiresAuth: requiresAuth);

  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) =>
      _send('DELETE', path, headers: headers, queryParams: queryParams, requiresAuth: requiresAuth);

  Future<dynamic> _send(
    String method,
    String path, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    bool isRetry = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);

    final reqHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (headers != null) ...headers,
    };

    if (requiresAuth) {
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        reqHeaders['Authorization'] = 'Bearer $token';
      }
    }

    http.Response response;
    try {
      final encodedBody = body != null ? jsonEncode(body) : null;
      switch (method.toUpperCase()) {
        case 'POST':
          response = await _client.post(uri, headers: reqHeaders, body: encodedBody).timeout(defaultTimeout);
          break;
        case 'PATCH':
          response = await _client.patch(uri, headers: reqHeaders, body: encodedBody).timeout(defaultTimeout);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: reqHeaders).timeout(defaultTimeout);
          break;
        default:
          response = await _client.get(uri, headers: reqHeaders).timeout(defaultTimeout);
      }
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message: 'Request timed out. Please check your connection.',
        errorCode: 'TIMEOUT',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
        errorCode: 'NETWORK_ERROR',
      );
    }

    // ── 401 Unauthorized handling with automated token refresh ──────────────
    if (response.statusCode == 401 && requiresAuth && !isRetry) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Retry the original request once with the new access token
        return _send(
          method,
          path,
          body: body,
          headers: headers,
          queryParams: queryParams,
          requiresAuth: requiresAuth,
          isRetry: true,
        );
      } else {
        await clearTokens();
        throw const ApiException(
          statusCode: 401,
          message: 'Session expired. Please log in again.',
          errorCode: 'UNAUTHORIZED',
        );
      }
    }

    return _processResponse(response);
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final uri = Uri.parse('$baseUrl/api/v1/auth/refresh');
      final res = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic> && data['access_token'] != null) {
          await saveTokens(
            accessToken: data['access_token'].toString(),
            refreshToken: (data['refresh_token'] ?? refreshToken).toString(),
          );
          return true;
        }
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }
    return false;
  }

  dynamic _processResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String message = 'Request failed (${response.statusCode})';
    String? errorCode;
    dynamic details;

    if (decoded is Map<String, dynamic>) {
      message = (decoded['detail'] ?? decoded['message'] ?? message).toString();
      errorCode = decoded['error_code']?.toString();
      details = decoded['details'];
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      errorCode: errorCode,
      details: details,
    );
  }
}
