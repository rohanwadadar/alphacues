import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/config/app_config.dart';

void main() {
  testWidgets('AppConfig.apiBaseUrl uses dart-define default', (WidgetTester tester) async {
    // Tests that the default value is read correctly when no dart-define is provided.
    AppConfig.initialize();
    expect(AppConfig.instance.apiBaseUrl, 'http://127.0.0.1:5000');
  });
}
