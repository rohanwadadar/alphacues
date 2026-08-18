import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/config/app_config.dart';

void main() {
  test('AppConfig.apiBaseUrl uses dart-define default', () {
    AppConfig.initialize();
    expect(AppConfig.instance.apiBaseUrl, 'http://localhost:5000');
  });
}
