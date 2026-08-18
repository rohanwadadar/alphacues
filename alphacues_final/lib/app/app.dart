import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_session.dart';
import 'auth_bootstrap.dart';
import '../core/realtime/socket_client.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

import '../core/routing/deep_link_handler.dart';
import '../core/push/notification_tap_handler.dart';

import '../features/splash/presentation/splash_screen.dart';

class AlphaCuesApp extends ConsumerStatefulWidget {
  const AlphaCuesApp({super.key});

  @override
  ConsumerState<AlphaCuesApp> createState() => _AlphaCuesAppState();
}

class _AlphaCuesAppState extends ConsumerState<AlphaCuesApp> {
  DeepLinkHandler? _deepLinkHandler;
  NotificationTapHandler? _notificationTapHandler;

  @override
  void initState() {
    super.initState();
    // Initialize DeepLinkHandler after a short delay so the router is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(goRouterProvider);
      
      _deepLinkHandler = DeepLinkHandler(router);
      _deepLinkHandler?.initialize();

      _notificationTapHandler = NotificationTapHandler(router);
      _notificationTapHandler?.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authSessionProvider);
    final router = ref.watch(goRouterProvider);

    return AuthBootstrap(
      child: SocketLifecycleBridge(
        child: authState.isLoading
            ? MaterialApp(
                title: 'Alpha Cues',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: ThemeMode.light,
                home: const SplashScreen(),
              )
            : MaterialApp.router(
                title: 'Alpha Cues',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: ThemeMode.light,
                routerConfig: router,
              ),
      ),
    );
  }
}