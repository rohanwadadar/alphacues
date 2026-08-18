import 'package:flutter/material.dart';

import 'stale_banner.dart';

/// Mobile shell layout for Android and iOS.
///
/// Applies [SafeArea] with `top: true, bottom: false` so that the
/// StaleBanner and page body are never obscured by the iPhone
/// notch / Dynamic Island or Android status bar cutout.
///
/// `bottom: false` is intentional — Material 3 [NavigationBar] consumes
/// the bottom window padding (home-indicator / gesture nav bar) internally,
/// so we must not double-apply it here or content will be pushed up too far.
class MobileShell extends StatelessWidget {
  const MobileShell({
    super.key,
    required this.body,
    this.bottomNavigationBar,
  });

  final Widget body;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SafeArea top=true → keeps content below Dynamic Island / notch.
      // SafeArea bottom=false → NavigationBar handles its own bottom insets.
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StaleBanner(),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
