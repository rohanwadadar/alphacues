import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const _pinKey = 'APP_PIN';
  static const _lockEnabledKey = 'APP_LOCK_ENABLED';
  static const _biometricEnabledKey = 'BIOMETRIC_ENABLED';

  // 🔢 PIN
  static Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  static Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  static Future<bool> hasPin() async {
    return (await getPin()) != null;
  }

  // 🔐 APP LOCK
  static Future<void> setAppLockEnabled(bool enabled) async {
    await _storage.write(
      key: _lockEnabledKey,
      value: enabled ? '1' : '0',
    );
  }

  static Future<bool> isAppLockEnabled() async {
    final v = await _storage.read(key: _lockEnabledKey);
    return v == '1';
  }

  // 🧬 BIOMETRICS
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled ? '1' : '0',
    );
  }

  static Future<bool> isBiometricEnabled() async {
    final v = await _storage.read(key: _biometricEnabledKey);
    return v == '1';
  }

  // 🚪 LOGOUT / RESET
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
