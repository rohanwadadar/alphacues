import 'package:flutter/material.dart';

/// SafeArea wrapper for feature screens.
class SafeScreen extends StatelessWidget {
  const SafeScreen({
    super.key,
    required this.child,
    this.bottom = true,
    this.top = true,
  });

  final Widget child;
  final bool bottom;
  final bool top;

  @override
  Widget build(BuildContext context) {
    return SafeArea(top: top, bottom: bottom, child: child);
  }
}
