import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tutor_app/auth/auth_service.dart';
import 'package:tutor_app/auth/auth_storage.dart';
import 'package:tutor_app/settings/app_settings.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class FcmService {
  factory FcmService() => instance;

  FcmService._();

  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AuthService _authService = AuthService();
  final AuthStorage _authStorage = AuthStorage();

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'tutor_alerts',
    'Tutor alerts',
    description: 'Lesson reminders and payment alerts',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
      );

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);
      await androidPlugin?.requestNotificationsPermission();

      _foregroundSub = FirebaseMessaging.onMessage.listen(_showForegroundMessage);
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((String token) {
        unawaited(_syncTokenToApi(token));
      });
    } on MissingPluginException {
      // Plugins unavailable in some test environments.
    } catch (error) {
      debugPrint('FCM initialize failed: $error');
    }
  }

  Future<String?> getDeviceToken() async {
    try {
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
      return await _messaging.getToken();
    } on MissingPluginException {
      return null;
    } catch (error) {
      debugPrint('FCM token fetch failed: $error');
      return null;
    }
  }

  Future<void> syncTokenForSession({required String token}) async {
    final bool enabled = await AppSettings.notificationsEnabled();
    if (!enabled) {
      return;
    }
    final String? fcmToken = await getDeviceToken();
    if (fcmToken == null || fcmToken.isEmpty) {
      return;
    }
    await _pushToken(
      authToken: token,
      fcmToken: fcmToken,
      enabled: true,
      clearFcmToken: false,
    );
  }

  Future<void> setNotificationsEnabled({
    required String authToken,
    required bool enabled,
  }) async {
    await AppSettings.setNotificationsEnabled(enabled);
    if (!enabled) {
      await _pushToken(
        authToken: authToken,
        fcmToken: null,
        enabled: false,
        clearFcmToken: true,
      );
      try {
        await _messaging.deleteToken();
      } catch (_) {}
      return;
    }

    final String? fcmToken = await getDeviceToken();
    await _pushToken(
      authToken: authToken,
      fcmToken: fcmToken,
      enabled: true,
      clearFcmToken: false,
    );
  }

  Future<void> _syncTokenToApi(String fcmToken) async {
    final bool enabled = await AppSettings.notificationsEnabled();
    if (!enabled) {
      return;
    }
    final String? authToken = await _authStorage.readToken();
    if (authToken == null || authToken.isEmpty) {
      return;
    }
    await _pushToken(
      authToken: authToken,
      fcmToken: fcmToken,
      enabled: true,
      clearFcmToken: false,
    );
  }

  Future<void> _pushToken({
    required String authToken,
    required String? fcmToken,
    required bool enabled,
    required bool clearFcmToken,
  }) async {
    try {
      await _authService.updateProfile(
        token: authToken,
        fcmToken: clearFcmToken ? null : fcmToken,
        clearFcmToken: clearFcmToken,
        notificationsEnabled: enabled,
      );
    } on AuthException catch (error) {
      debugPrint('FCM profile sync failed: ${error.message}');
    } catch (error) {
      debugPrint('FCM profile sync failed: $error');
    }
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    if (notification == null) {
      return;
    }

    final String title = notification.title ?? 'Tutor';
    final String body = notification.body ?? '';
    final String payload = jsonEncode(message.data);

    try {
      await _localNotifications.show(
        id: notification.hashCode,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: payload,
      );
    } catch (error) {
      debugPrint('Foreground notification failed: $error');
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
  }
}

/// Platform helper kept for callers that need OS checks without importing dart:io.
bool get fcmIsMobile => !kIsWeb && (Platform.isIOS || Platform.isAndroid);
