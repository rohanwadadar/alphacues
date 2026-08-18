import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/auth/auth_session.dart';

/// Best-effort FCM device registration after login.
class DeviceRegistrationService {
  DeviceRegistrationService({
    required Dio dio,
    FirebaseMessaging? messaging,
    DeviceInfoPlugin? deviceInfo,
    Future<PackageInfo> Function()? packageInfoLoader,
  }) : _dio = dio,
       _messaging = messaging,
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
       _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform;

  final Dio _dio;
  final FirebaseMessaging? _messaging;
  final DeviceInfoPlugin _deviceInfo;
  final Future<PackageInfo> Function() _packageInfoLoader;

  Future<void> registerBestEffort() async {
    try {
      final fcmToken = await _messaging?.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        return;
      }

      final platform = _platformName();
      final deviceId = await _stableDeviceId();
      final packageInfo = await _packageInfoLoader();

      // Request permission for push notifications
      if (!kIsWeb) {
        final settings = await _messaging?.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings?.authorizationStatus != AuthorizationStatus.authorized) {
          debugPrint('Push permission not granted');
          return;
        }

        // Setup token refresh listener
        _messaging?.onTokenRefresh.listen((newToken) async {
          try {
            await _dio.post<Map<String, dynamic>>(
              '/api/v1/devices/register',
              data: {
                'fcmToken': newToken,
                'platform': platform,
                'deviceId': deviceId,
                'appVersion': packageInfo.version,
              },
            );
          } catch (e) {
            debugPrint('Failed to register refreshed token: $e');
          }
        });
      }

      await _dio.post<Map<String, dynamic>>(
        '/api/v1/devices/register',
        data: {
          'fcmToken': fcmToken,
          'platform': platform,
          'deviceId': deviceId,
          'appVersion': packageInfo.version,
        },
      );
    } catch (e, st) {
      debugPrint('Device registration failed (ignored): $e\n$st');
    }
  }

  String _platformName() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'android';
  }

  Future<String> _stableDeviceId() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return info.id;
    }
    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return info.identifierForVendor ?? 'unknown-ios-device';
    }
    return 'unknown-device';
  }
}

final deviceRegistrationProvider = Provider<DeviceRegistrationService>((ref) {
  return DeviceRegistrationService(dio: ref.watch(dioProvider));
});
