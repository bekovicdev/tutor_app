import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FcmService {
  Future<String?> getDeviceToken() async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final String? token = await messaging.getToken();
      return token;
    } on MissingPluginException {
      return null;
    } catch (error) {
      debugPrint('FCM token fetch failed: $error');
      return null;
    }
  }
}
