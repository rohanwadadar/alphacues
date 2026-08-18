import 'package:flutter/material.dart';
import 'package:test_project/features/security/pin_lock_screen.dart';
import 'package:test_project/features/security/secure_storage_service.dart';
import 'package:test_project/features/security/set_pin_screen.dart';


class AppLockWrapper extends StatefulWidget {
  final Widget child;
  const AppLockWrapper({required this.child, super.key});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper>
    with WidgetsBindingObserver {
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _lockIfNeeded());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lockIfNeeded();
    }
  }
Future<void> _lockIfNeeded() async {
  if (_locked) return;

  final enabled = await SecureStorageService.isAppLockEnabled();
  if (!enabled) return;

  final hasPin = await SecureStorageService.hasPin();

  _locked = true;

  // 🔑 FIRST TIME → FORCE PIN SETUP
  if (!hasPin) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const SetPinScreen(),
      ),
    );
    _locked = false;
    return;
  }

  // 🔐 NORMAL LOCK
  await Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const PinLockScreen(),
    ),
  );

  _locked = false;
}


  @override
  Widget build(BuildContext context) => widget.child;
}
