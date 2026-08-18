import 'core/auth/auth_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final container = ProviderContainer();
  container.read(authSessionProvider.notifier).bootstrapSession();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AlphaCuesApp(),
    ),
  );
}
