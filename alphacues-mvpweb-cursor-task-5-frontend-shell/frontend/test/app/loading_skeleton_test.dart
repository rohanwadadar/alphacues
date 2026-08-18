import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/theme/app_theme.dart';
import 'package:frontend/core/widgets/loading_skeleton.dart';

void main() {
  testWidgets('renders at given dimensions with no overflow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(child: LoadingSkeleton(width: 120, height: 24)),
        ),
      ),
    );
    await tester.pump();

    final box = tester.renderObject(find.byType(LoadingSkeleton)) as RenderBox;
    expect(box.size.width, 120);
    expect(box.size.height, 24);
    expect(tester.takeException(), isNull);
  });
}
