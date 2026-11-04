import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../auth/auth_session_provider.dart';
import '../network/api_client.dart';

final pushTokenRepositoryProvider = Provider<PushTokenRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PushTokenRepository(dio);
});

class PushTokenRepository {
  final Dio _dio;

  PushTokenRepository(this._dio);

  Future<void> registerToken(String fcmToken) async {
    final platformInfo = await PlatformInfo.get();
    await _dio.post('/devices', data: {
      'deviceId': platformInfo.deviceId,
      'fcmToken': fcmToken,
      'platform': platformInfo.osName,
      'appVersion': platformInfo.appVersion,
    });
  }

  Future<void> unregisterToken() async {
    final platformInfo = await PlatformInfo.get();
    await _dio.delete('/devices/${platformInfo.deviceId}');
  }
}

class PlatformInfo {
  final String deviceId;
  final String osName;
  final String? appVersion;

  PlatformInfo({
    required this.deviceId,
    required this.osName,
    this.appVersion,
  });

  static Future<PlatformInfo> get() async {
    // In a real app, use device_info_plus and package_info_plus
    // For MVP, we'll provide basic info.
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = 'unknown';
    String osName = 'unknown';

    if (const bool.fromEnvironment('dart.library.html')) {
      osName = 'web';
    } else {
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
          osName = 'android';
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? 'unknown';
          osName = 'ios';
        }
      } catch (e) {
        // Fallback
      }
    }

    return PlatformInfo(
      deviceId: deviceId,
      osName: osName,
      appVersion: '1.0.0', // Could use package_info_plus
    );
  }
}
