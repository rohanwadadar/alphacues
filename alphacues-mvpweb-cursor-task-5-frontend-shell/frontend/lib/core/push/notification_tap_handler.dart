import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class NotificationTapHandler {
  final GoRouter _router;

  NotificationTapHandler(this._router);

  Future<void> initialize() async {
    if (kIsWeb) return;

    // Handle tap from cold start
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Handle tap while app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('deepLink')) {
      final String deepLink = data['deepLink'];
      if (deepLink.isNotEmpty) {
        _router.go(deepLink);
      }
    }
  }
}
