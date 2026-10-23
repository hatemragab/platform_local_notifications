import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_local_notifications/platform_local_notifications.dart';

import 'package:example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    calls.clear();
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'initialize' => true,
        'getNotificationAppLaunchDetails' => {'notificationLaunchedApp': false},
        _ => null,
      };
    });
  });

  tearDown(() {
    PlatformNotifier.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets('renders the notification demo controls', (tester) async {
    await tester.pumpWidget(const MyApp(initializeNotifications: false));

    expect(find.text('Platform Local Notifications'), findsOneWidget);
    expect(find.text('Service Status'), findsOneWidget);
    expect(find.text('Request Permissions'), findsOneWidget);
    expect(find.text('Show Simple Notification'), findsOneWidget);
    expect(find.text('Show Chat Notification'), findsOneWidget);
    expect(find.text('Cancel All Notifications'), findsOneWidget);
  });

  testWidgets('normal launch is not reported as a notification launch', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Initialized'), findsOneWidget);
    expect(
      find.text('App was not launched from a notification'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('initialization can finish after the screen is disposed', (
    tester,
  ) async {
    final initialization = Completer<bool>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'initialize') return initialization.future;
      return null;
    });
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    initialization.complete(true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('standalone Material demo sends the notification payload', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show Simple Notification'));
    await tester.pumpAndSettle();
    final shown = calls.lastWhere((call) => call.method == 'show');
    expect(
      (shown.arguments as Map)['payload'],
      startsWith('simple_notification_'),
    );
    expect(
      find.textContaining('Simple notification sent (payload:'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification facade works under standalone Cupertino', (
    tester,
  ) async {
    await PlatformNotifier.initialize(appName: 'Cupertino Consumer');
    await tester.pumpWidget(
      cupertino.CupertinoApp(
        home: cupertino.CupertinoPageScaffold(
          child: Center(
            child: cupertino.CupertinoButton(
              onPressed: () => PlatformNotifier.showNotification(
                model: const NotificationModel(
                  id: 42,
                  title: 'Cupertino',
                  body: 'Native notification',
                  payload: 'cupertino-42',
                ),
              ),
              child: const Text('Notify'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Notify'));
    await tester.pumpAndSettle();
    final shown = calls.lastWhere((call) => call.method == 'show');
    expect((shown.arguments as Map)['payload'], 'cupertino-42');
    expect(tester.takeException(), isNull);
  });
}
