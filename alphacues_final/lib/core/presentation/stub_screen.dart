import 'package:flutter/material.dart';

/// Minimal placeholder screen showing the route name.
class StubScreen extends StatelessWidget {
  const StubScreen({
    super.key,
    required this.routeLabel,
    this.wrapSafeArea = true,
  });

  final String routeLabel;
  final bool wrapSafeArea;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          routeLabel,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ),
    );

    if (wrapSafeArea) {
      return SafeArea(child: content);
    }
    return content;
  }
}
