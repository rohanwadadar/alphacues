import 'package:flutter/material.dart';

import '../../app/router/app_routes.dart';
import 'stub_screen.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StubScreen(routeLabel: AppLabels.notFound);
  }
}
