import 'package:flutter/material.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/presentation/stub_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StubScreen(routeLabel: AppLabels.settings);
  }
}
