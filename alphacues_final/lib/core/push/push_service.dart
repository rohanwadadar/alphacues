import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'push_token_repository.dart';

final pushServiceProvider = Provider<PushService>((ref) {
  final repo = ref.watch(pushTokenRepositoryProvider);
  return PushService(repo);
});

class PushService {
  final PushTokenRepository _repository;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  PushService(this._repository);

  Future<void> initialize() async {
    if (kIsWeb) return;

    // Request permission (Android 13+ and iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted push permission');
      await _registerCurrentToken();

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((fcmToken) {
        _repository.registerToken(fcmToken).catchError((err) {
          debugPrint('Failed to refresh token: $err');
        });
      });
    } else {
      debugPrint('User declined or has not accepted push permission');
    }
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _repository.registerToken(token);
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  Future<void> clearToken() async {
    if (kIsWeb) return;
    try {
      await _repository.unregisterToken();
      // We don't delete the token from Firebase here unless we want to stop all pushes to this device for all users.
      // Usually, just removing it from the backend is enough.
    } catch (e) {
      debugPrint('Failed to clear push token: $e');
    }
  }
}
