import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mecha_connect/services/api_client.dart';
import 'package:mecha_connect/services/push_notification_service.dart';

class FakeApiClient extends Fake implements ApiClient {
  final List<Map<String, dynamic>> postCalls = [];
  final List<Map<String, dynamic>> deleteCalls = [];

  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    postCalls.add({
      'path': path,
      'body': body,
      'requiresAuth': requiresAuth,
    });
    return {'id': 'token-123', 'is_active': true};
  }

  @override
  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    deleteCalls.add({
      'path': path,
      'queryParams': queryParams,
      'requiresAuth': requiresAuth,
    });
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PushNotificationService', () {
    test('initial state has no active token and not initialized', () {
      final service = PushNotificationService();
      expect(service.isInitialized, isFalse);
      expect(service.currentFcmToken, isNull);
      expect(service.pendingPayload, isNull);
    });

    test('registerDeviceToken skips when user is not logged in', () async {
      SharedPreferences.setMockInitialValues({'is_logged_in': false});
      final fakeApi = FakeApiClient();
      final service = PushNotificationService(apiClient: fakeApi);

      final result = await service.registerDeviceToken('test-fcm-token');
      expect(result, isFalse);
      expect(fakeApi.postCalls, isEmpty);
    });

    test('registerDeviceToken posts to backend when user is logged in', () async {
      SharedPreferences.setMockInitialValues({'is_logged_in': true});
      final fakeApi = FakeApiClient();
      final service = PushNotificationService(apiClient: fakeApi);

      final result = await service.registerDeviceToken('valid-device-token');
      expect(result, isTrue);
      expect(fakeApi.postCalls.length, equals(1));
      expect(fakeApi.postCalls.first['path'], equals('/api/v1/device-tokens'));
      expect(fakeApi.postCalls.first['requiresAuth'], isTrue);
      final body = fakeApi.postCalls.first['body'] as Map<String, dynamic>;
      expect(body['fcm_token'], equals('valid-device-token'));
      expect(body['platform'], isNotNull);
    });

    test('stores pending payload when unauthenticated', () async {
      SharedPreferences.setMockInitialValues({'is_logged_in': false});
      final service = PushNotificationService();

      final payload = {
        'entity_type': 'booking',
        'entity_id': '8f3b2a10-4c5d-6e7f-8a9b-0c1d2e3f4a5b',
        'status': 'enRoute',
      };

      service.handleNotificationPayload(payload);
      expect(service.pendingPayload, equals(payload));
    });

    test('unregisterDeviceToken calls delete when token is active', () async {
      final fakeApi = FakeApiClient();
      final service = PushNotificationService(apiClient: fakeApi);

      // Simulate token obtained
      SharedPreferences.setMockInitialValues({'is_logged_in': true});
      await service.registerDeviceToken('token-to-unregister');

      // Now unregister
      await service.unregisterDeviceToken();
      expect(fakeApi.deleteCalls.length, equals(1));
      expect(fakeApi.deleteCalls.first['path'], equals('/api/v1/device-tokens'));
      expect(fakeApi.deleteCalls.first['queryParams'], equals({'fcm_token': 'token-to-unregister'}));
      expect(fakeApi.deleteCalls.first['requiresAuth'], isTrue);
      expect(service.currentFcmToken, isNull);
    });

    test('unregisterDeviceToken runs safely when no token cached', () async {
      final service = PushNotificationService();
      await service.unregisterDeviceToken();
      expect(service.currentFcmToken, isNull);
    });
  });
}
