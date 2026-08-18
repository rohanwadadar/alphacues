import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_session.dart';

/// Kicks off cold-start session restoration once per app launch.
class AuthBootstrap extends ConsumerStatefulWidget {
  const AuthBootstrap({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AuthBootstrap> createState() => _AuthBootstrapState();
}

class _AuthBootstrapState extends ConsumerState<AuthBootstrap> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(authSessionProvider.notifier).bootstrapSession(),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
