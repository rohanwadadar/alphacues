import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class DeepLinkHandler {
  final _appLinks = AppLinks();
  final GoRouter _router;

  DeepLinkHandler(this._router);

  void initialize() {
    // Handle initial link (cold start)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // Handle deep links when app is already running (warm start)
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Error listening to deep links: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received deep link: $uri');
    // We want to pass the path and query parameters to go_router
    // GoRouter will handle the matching based on its route definitions.
    // Ensure we only pass the path and query string, e.g., /symbols/AAPL?query=1
    final path = uri.path;
    final query = uri.query;
    final location = query.isNotEmpty ? '$path?$query' : path;
    if (location.isNotEmpty) {
      _router.go(location);
    }
  }
}
