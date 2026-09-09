import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mecha_connect/features/auth/screens/login_screen.dart';
import 'package:mecha_connect/features/mechanic/screens/live_tracking_screen.dart';
import 'package:mecha_connect/services/api_client.dart';

/// Top-level background message entry point required by Firebase Messaging.
///
/// MUST be annotated with @pragma('vm:entry-point') so the Flutter engine
/// does not tree-shake it when the app is launched in the background isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // If already initialized or credentials missing
  }
  debugPrint('Handling FCM background message ID: ${message.messageId}');
}

/// Orchestrates push notifications, permissions, FCM tokens, and deep-links.
class PushNotificationService extends ChangeNotifier {
  final ApiClient _apiClient;

  PushNotificationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Global navigator key allowing navigation from push notification taps
  /// even when a direct BuildContext is not available.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  String? _currentFcmToken;
  bool _isInitialized = false;
  Map<String, dynamic>? _pendingNotificationPayload;

  String? get currentFcmToken => _currentFcmToken;
  bool get isInitialized => _isInitialized;
  Map<String, dynamic>? get pendingPayload => _pendingNotificationPayload;

  /// Initializes Firebase and push notification listeners.
  ///
  /// Safe to call anywhere: fails gracefully if Firebase is not yet provisioned.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize core if needed
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint('PushNotificationService: Firebase.initializeApp notice: $e');
      }

      final messaging = FirebaseMessaging.instance;

      // 2. Set foreground presentation options
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 4. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received: ${message.notification?.title}');
        _handleForegroundMessage(message);
      });

      // 5. App opened from background state listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM onMessageOpenedApp: ${message.data}');
        handleNotificationPayload(message.data);
      });

      // 6. Check for cold-start (terminated state) notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM getInitialMessage (cold start): ${initialMessage.data}');
        _pendingNotificationPayload = initialMessage.data;
      }

      // 7. Token refresh listener
      messaging.onTokenRefresh.listen((String newToken) {
        debugPrint('FCM Token Refreshed: $newToken');
        _currentFcmToken = newToken;
        registerDeviceToken(newToken);
      });

      _isInitialized = true;
      notifyListeners();

      // 8. Attempt initial token registration if already authenticated
      await registerCurrentToken();
    } catch (e) {
      debugPrint('PushNotificationService initialization skipped/failed: $e');
    }
  }

  /// Requests notification permissions (Android 13+ / iOS).
  Future<NotificationSettings?> requestPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final prefs = await SharedPreferences.getInstance();
      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized;
      await prefs.setBool('notifications_push_granted', isGranted);

      if (isGranted) {
        await registerCurrentToken();
      }
      return settings;
    } catch (e) {
      debugPrint('PushNotificationService.requestPermission error: $e');
      return null;
    }
  }

  /// Retrieves the active FCM token and registers it with the backend.
  Future<void> registerCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _currentFcmToken = token;
        await registerDeviceToken(token);
      }
    } catch (e) {
      debugPrint('PushNotificationService.registerCurrentToken error: $e');
    }
  }

  /// Sends the FCM token to the backend `/api/v1/device-tokens`.
  Future<bool> registerDeviceToken(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      if (!isLoggedIn) {
        debugPrint('Token registration skipped: user is not logged in.');
        return false;
      }

      String platform = 'android';
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        platform = 'ios';
      } else if (kIsWeb) {
        platform = 'web';
      }

      await _apiClient.post(
        '/api/v1/device-tokens',
        body: {
          'fcm_token': fcmToken,
          'platform': platform,
          'app_version': '1.0.0+1',
        },
        requiresAuth: true,
      );
      debugPrint('Device token successfully registered with Mecha Connect backend.');
      return true;
    } catch (e) {
      debugPrint('Device token registration failed (isolated): $e');
      return false;
    }
  }

  /// Unregisters the active FCM token from the backend upon logout.
  Future<void> unregisterDeviceToken() async {
    try {
      final token = _currentFcmToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _apiClient.delete(
          '/api/v1/device-tokens',
          queryParams: {'fcm_token': token},
          requiresAuth: true,
        );
        debugPrint('Device token unregistered from backend.');
      }
    } catch (e) {
      debugPrint('Device token unregistration error (isolated): $e');
    }
  }

  /// Handles notifications arriving while the app is active on screen.
  void _handleForegroundMessage(RemoteMessage message) {
    final navContext = navigatorKey.currentContext;
    if (navContext == null) return;

    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';

    ScaffoldMessenger.maybeOf(navContext)?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (body.isNotEmpty) Text(body),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            handleNotificationPayload(message.data, context: navContext);
          },
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Dispatches deep-link navigation based on FCM payload data.
  void handleNotificationPayload(
    Map<String, dynamic> data, {
    BuildContext? context,
  }) async {
    final targetContext = context ?? navigatorKey.currentContext;
    if (targetContext == null) {
      _pendingNotificationPayload = data;
      return;
    }

    final entityType = data['entity_type']?.toString();
    final entityId = data['entity_id']?.toString();

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!isLoggedIn) {
      // User is logged out: preserve payload and route to LoginScreen
      _pendingNotificationPayload = data;
      Navigator.of(targetContext).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // Authenticated deep-link resolution
    if (entityType == 'booking' && entityId != null && entityId.isNotEmpty) {
      Navigator.of(targetContext).push(
        MaterialPageRoute(
          builder: (_) => LiveTrackingScreen(bookingId: entityId),
        ),
      );
      _pendingNotificationPayload = null;
    }
  }

  /// Consumes and executes any stored pending notification after user logs in.
  void consumePendingNotification(BuildContext context) {
    if (_pendingNotificationPayload != null) {
      final payload = _pendingNotificationPayload!;
      _pendingNotificationPayload = null;
      handleNotificationPayload(payload, context: context);
    }
  }
}
