import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  NetworkException(this.message, {this.statusCode});

  @override
  String toString() => "NetworkException: $message (Status: $statusCode)";
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String get baseUrl {
    final envUrl = dotenv.env['BACKEND_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Automatic fallback based on Platform (Web vs Android Emulator vs Host OS)
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    } else {
      return 'http://127.0.0.1:8000/api/v1';
    }
  }

  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {int retries = 3}) async {
    final activeBaseUrl = baseUrl;
    final uri = Uri.parse("$activeBaseUrl$path");
    final headers = {"Content-Type": "application/json"};
    final encodedBody = jsonEncode(body);

    debugPrint("BASE URL = $activeBaseUrl");
    debugPrint("REQUEST = $uri");

    int attempts = 0;
    while (attempts < retries) {
      try {
        attempts++;
        final response = await _client
            .post(uri, headers: headers, body: encodedBody)
            .timeout(const Duration(seconds: 30));

        debugPrint("RESPONSE STATUS = ${response.statusCode}");

        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        } else {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final ex = NetworkException(
            errorData['detail'] ?? "Server error occurred",
            statusCode: response.statusCode,
          );
          debugPrint("HTTP ERROR = $ex");
          throw ex;
        }
      } on SocketException catch (e) {
        debugPrint("SOCKET EXCEPTION = ${e.message} (attempt $attempts of $retries)");
        if (attempts >= retries) {
          final ex = NetworkException("Connection timed out. Check your backend status. Details: ${e.message}");
          debugPrint("THROW EXCEPTION = $ex");
          throw ex;
        }
        await Future.delayed(Duration(seconds: attempts));
      } on TimeoutException catch (e) {
        debugPrint("TIMEOUT EXCEPTION = $e (attempt $attempts of $retries)");
        if (attempts >= retries) {
          final ex = NetworkException("Server took too long to respond. Timeout exceeded.");
          debugPrint("THROW EXCEPTION = $ex");
          throw ex;
        }
        await Future.delayed(Duration(seconds: attempts));
      } catch (e) {
        debugPrint("UNEXPECTED ERROR = $e");
        rethrow;
      }
    }
    throw NetworkException("Failed to complete request after $retries retries.");
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? queryParameters, int retries = 3}) async {
    final activeBaseUrl = baseUrl;
    Uri uri = Uri.parse("$activeBaseUrl$path");
    if (queryParameters != null) {
      uri = uri.replace(queryParameters: queryParameters);
    }
    final headers = {"Content-Type": "application/json"};

    debugPrint("BASE URL = $activeBaseUrl");
    debugPrint("REQUEST = $uri");

    int attempts = 0;
    while (attempts < retries) {
      try {
        attempts++;
        final response = await _client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 30));

        debugPrint("RESPONSE STATUS = ${response.statusCode}");

        if (response.statusCode == 200) {
          return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        } else {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final ex = NetworkException(
            errorData['detail'] ?? "Server error occurred",
            statusCode: response.statusCode,
          );
          debugPrint("HTTP ERROR = $ex");
          throw ex;
        }
      } on SocketException catch (e) {
        debugPrint("SOCKET EXCEPTION = ${e.message} (attempt $attempts of $retries)");
        if (attempts >= retries) {
          final ex = NetworkException("Connection timed out. Details: ${e.message}");
          debugPrint("THROW EXCEPTION = $ex");
          throw ex;
        }
        await Future.delayed(Duration(seconds: attempts));
      } on TimeoutException catch (e) {
        debugPrint("TIMEOUT EXCEPTION = $e (attempt $attempts of $retries)");
        if (attempts >= retries) {
          final ex = NetworkException("Server took too long to respond. Timeout exceeded.");
          debugPrint("THROW EXCEPTION = $ex");
          throw ex;
        }
        await Future.delayed(Duration(seconds: attempts));
      } catch (e) {
        debugPrint("UNEXPECTED ERROR = $e");
        rethrow;
      }
    }
    throw NetworkException("Failed to complete request after $retries retries.");
  }
}
