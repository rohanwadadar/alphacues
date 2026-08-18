import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/platform/connectivity_service.dart';
import 'package:frontend/core/widgets/loading_skeleton.dart';
import 'package:frontend/features/notifications/data/notifications_notifier.dart';
import 'package:frontend/features/notifications/presentation/notifications_panel.dart';

class _OnlineConnectivity extends ConnectivityService {
  @override
  ConnectivityStatus build() => const ConnectivityStatus(isOnline: true);
}

class _EmptyNotificationsNotifier extends NotificationsNotifier {
  @override
  Future<List<NotificationModel>> build() async => const [];
}

class _LoadingNotificationsNotifier extends NotificationsNotifier {
  @override
  Future<List<NotificationModel>> build() async {
    await Completer<void>().future;
    return const [];
  }
}

class _TwoItemNotificationsNotifier extends NotificationsNotifier {
  @override
  Future<List<NotificationModel>> build() async {
    return const [
      NotificationModel(
        notificationId: '1',
        alertId: '10',
        userId: '1',
        title: 'Unread title',
        body: 'Unread body',
        isRead: false,
        createdAt: '2026-05-13T14:30:02Z',
      ),
      NotificationModel(
        notificationId: '2',
        alertId: '11',
        userId: '1',
        title: 'Read title',
        body: 'Read body',
        isRead: true,
        createdAt: '2026-05-12T14:30:02Z',
      ),
    ];
  }
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectivityServiceProvider.overrideWith(_OnlineConnectivity.new),
        ...overrides,
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const NotificationsPanel(),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty notifier state shows caught up message', (tester) async {
    await _pumpPanel(
      tester,
      overrides: [
        notificationsProvider.overrideWith(_EmptyNotificationsNotifier.new),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text("You're all caught up"), findsOneWidget);
  });

  testWidgets('loading state shows skeleton and hides list rows', (tester) async {
    await _pumpPanel(
      tester,
      overrides: [
        notificationsProvider.overrideWith(_LoadingNotificationsNotifier.new),
      ],
    );
    await tester.pump();

    expect(find.byType(LoadingSkeleton), findsWidgets);
    expect(find.text("You're all caught up"), findsNothing);
  });

  testWidgets('two items render title and body', (tester) async {
    await _pumpPanel(
      tester,
      overrides: [
        notificationsProvider.overrideWith(_TwoItemNotificationsNotifier.new),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Unread title'), findsOneWidget);
    expect(find.text('Unread body'), findsOneWidget);
    expect(find.text('Read title'), findsOneWidget);
    expect(find.text('Read body'), findsOneWidget);
  });

  testWidgets('unread title is bold and read title is not bold', (tester) async {
    await _pumpPanel(
      tester,
      overrides: [
        notificationsProvider.overrideWith(_TwoItemNotificationsNotifier.new),
      ],
    );
    await tester.pumpAndSettle();

    final unreadTitle = tester.widget<Text>(find.text('Unread title'));
    final readTitle = tester.widget<Text>(find.text('Read title'));

    expect(unreadTitle.style?.fontWeight, FontWeight.w700);
    expect(readTitle.style?.fontWeight, FontWeight.w400);
  });
}
