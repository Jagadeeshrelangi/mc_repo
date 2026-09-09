import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mecha_connect/services/push_notification_service.dart';

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
      final service = PushNotificationService();

      final result = await service.registerDeviceToken('test-fcm-token');
      expect(result, isFalse);
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

    test('unregisterDeviceToken runs safely when no token cached', () async {
      final service = PushNotificationService();
      // Should not throw or crash
      await service.unregisterDeviceToken();
      expect(service.currentFcmToken, isNull);
    });
  });
}
