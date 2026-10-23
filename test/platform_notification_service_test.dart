import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_local_notifications/platform_local_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final service = PlatformNotificationService.instance;
  final calls = <MethodCall>[];
  Future<Object?> Function(MethodCall)? handler;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    handler = null;
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (handler != null) return handler!(call);
      return switch (call.method) {
        'initialize' => true,
        'requestNotificationsPermission' => true,
        'requestPermissions' => true,
        'getNotificationAppLaunchDetails' => {'notificationLaunchedApp': false},
        _ => null,
      };
    });
  });

  tearDown(() {
    service.dispose();
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  Future<void> initialize({NotificationData data = const NotificationData()}) =>
      service.initialize(appName: 'Test App', notificationData: data);

  Future<void> sendResponse({
    int type = 1,
    String? actionId,
    String? input,
  }) async {
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        MethodCall('didReceiveNotificationResponse', {
          'notificationId': 7,
          'notificationResponseType': type,
          'actionId': actionId,
          'input': input,
          'payload': 'chat-7',
        }),
      ),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);
  }

  test('operations require initialization', () async {
    expect(service.requestPermissions(), throwsStateError);
    expect(service.appLaunchNotification, throwsStateError);
    expect(
      service.showNotification(
        model: const NotificationModel(id: 1, title: '', body: ''),
      ),
      throwsStateError,
    );
    expect(
      service.showChatNotification(
        model: const ChatNotificationModel(
          id: 1,
          title: '',
          body: '',
          userName: '',
          userImageUrl: null,
        ),
      ),
      throwsStateError,
    );
    expect(service.cancelNotification(1), throwsStateError);
    expect(service.cancelAllNotifications(), throwsStateError);
  });

  test('blank app name does not initialize', () async {
    await expectLater(service.initialize(appName: '  '), throwsArgumentError);
    expect(calls, isEmpty);
  });

  test('concurrent initialization runs native setup once', () async {
    await Future.wait([initialize(), initialize()]);
    expect(calls.where((call) => call.method == 'initialize'), hasLength(1));
    expect(service.isInitialized, isTrue);
  });

  test('failed initialization is retryable', () async {
    handler = (call) async => call.method == 'initialize' ? false : null;
    await expectLater(initialize(), throwsStateError);
    expect(service.isInitialized, isFalse);
    handler = null;
    await initialize();
    expect(service.isInitialized, isTrue);
  });

  test('channel creation errors propagate and setup can be retried', () async {
    handler = (call) async {
      if (call.method == 'createNotificationChannel') {
        throw PlatformException(code: 'channel');
      }
      return true;
    };
    await expectLater(initialize(), throwsA(isA<PlatformException>()));
    expect(service.isInitialized, isFalse);
    handler = null;
    await initialize();
  });

  test('dispose releases action port and allows reinitialization', () async {
    await initialize();
    final closed = Completer<void>();
    final oldSubscription = service.actionStream.listen(
      (_) {},
      onDone: closed.complete,
    );
    service.dispose();
    await closed.future;
    await oldSubscription.cancel();
    final events = <BaseNotificationAction>[];
    final subscription = service.actionStream.listen(events.add);
    addTearDown(subscription.cancel);
    await initialize();
    await sendResponse(type: 0);
    expect(events.single, isA<NotificationClickAction>());
    expect(events.single.payload, 'chat-7');
  });

  test(
    'dispose while initialization is pending cannot resurrect service',
    () async {
      final started = Completer<void>();
      final finish = Completer<void>();
      handler = (call) async {
        if (call.method == 'initialize') {
          started.complete();
          await finish.future;
        }
        return true;
      };
      final pending = initialize();
      await started.future;
      service.dispose();
      finish.complete();
      await pending;
      expect(service.isInitialized, isFalse);
      handler = null;
      await initialize();
      expect(service.isInitialized, isTrue);
    },
  );

  test(
    'configured channel controls creation, display and repeated setup',
    () async {
      const customChannel = AndroidNotificationChannel(
        'quiet',
        'Quiet',
        description: 'Quiet messages',
        importance: Importance.low,
        playSound: false,
      );
      await initialize(
        data: const NotificationData(androidNotificationChannel: customChannel),
      );
      await service.initialize(appName: 'Ignored');
      await service.showNotification(
        model: const NotificationModel(
          id: 7,
          title: 'Title',
          body: 'Body',
          payload: 'chat-7',
        ),
      );
      final arguments = calls.last.arguments as Map;
      final details = arguments['platformSpecifics'] as Map;
      expect(calls.where((call) => call.method == 'initialize'), hasLength(1));
      expect(arguments['payload'], 'chat-7');
      expect(details['channelId'], 'quiet');
      expect(details['channelName'], 'Quiet');
      expect(details['playSound'], isFalse);
      expect(details['setAsGroupSummary'], isFalse);
    },
  );

  test('invalid IDs fail before calling native display', () async {
    await initialize();
    final before = calls.length;
    for (final id in [-0x80000001, 0x80000000]) {
      await expectLater(
        service.showNotification(
          model: NotificationModel(id: id, title: '', body: ''),
        ),
        throwsArgumentError,
      );
    }
    expect(calls, hasLength(before));
    await service.showNotification(
      model: const NotificationModel(id: 0, title: '', body: ''),
    );
  });

  test(
    'Android chat has messaging style and natively dismissed actions',
    () async {
      await initialize();
      await service.showChatNotification(
        model: const ChatNotificationModel(
          id: 7,
          title: 'Chat',
          body: 'Hi',
          userImageUrl: null,
          userName: 'Alex',
          replyLabel: 'Respond',
          replyHint: 'Type here',
        ),
      );
      final details = (calls.last.arguments as Map)['platformSpecifics'] as Map;
      final actions = details['actions'] as List;
      expect(actions, hasLength(2));
      expect((actions[1] as Map)['title'], 'Respond');
      expect(
        actions.every(
          (action) => (action as Map)['cancelNotification'] == true,
        ),
        isTrue,
      );
      expect(details['styleInformation'], isA<Map>());
    },
  );

  test('foreground reply and mark-read emit payload and cancel', () async {
    await initialize();
    final events = <BaseNotificationAction>[];
    final subscription = service.actionStream.listen(events.add);
    addTearDown(subscription.cancel);
    await sendResponse(
      actionId: NotificationConstants.replyActionId,
      input: 'Hello',
    );
    await sendResponse(actionId: NotificationConstants.markAsReadActionId);
    await sendResponse(actionId: 'unknown');
    expect(events, hasLength(2));
    expect((events.first as NotificationReplyAction).replyText, 'Hello');
    expect(events.last, isA<NotificationMarkReadAction>());
    expect(events.every((event) => event.payload == 'chat-7'), isTrue);
    expect(calls.where((call) => call.method == 'cancel'), hasLength(2));
  });

  test(
    'dismissal never emits reply actions or cancels another notification',
    () async {
      await initialize();
      final events = <BaseNotificationAction>[];
      final subscription = service.actionStream.listen(events.add);
      addTearDown(subscription.cancel);
      await sendResponse(
        type: NotificationResponseType.notificationDismissed.index,
        actionId: NotificationConstants.replyActionId,
        input: 'Ignored',
      );
      await onDidReceiveBackgroundNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.notificationDismissed,
          id: 7,
          actionId: NotificationConstants.replyActionId,
          input: 'Ignored',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
      expect(calls.where((call) => call.method == 'cancel'), isEmpty);
    },
  );

  test('background response forwards through the action receiver', () async {
    await initialize();
    final action = service.actionStream.first;
    await onDidReceiveBackgroundNotificationResponse(
      const NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
        id: 7,
        actionId: NotificationConstants.replyActionId,
        input: 'Background reply',
        payload: 'chat-7',
      ),
    );
    final event = await action.timeout(const Duration(seconds: 2));
    expect((event as NotificationReplyAction).replyText, 'Background reply');
    expect(event.payload, 'chat-7');
    await Future<void>.delayed(Duration.zero);
    expect(calls.last.method, 'cancel');
  });

  test('permission denial is returned', () async {
    await initialize();
    handler = (_) async => false;
    expect(await service.requestPermissions(), isFalse);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
    test(
      '$platform initializes its delivery backend and handles permission denial',
      () async {
        debugDefaultTargetPlatformOverride = platform;
        if (platform == TargetPlatform.iOS) {
          IOSFlutterLocalNotificationsPlugin.registerWith();
        } else {
          MacOSFlutterLocalNotificationsPlugin.registerWith();
        }
        handler = (_) async => false;
        await initialize();
        expect(service.isInitialized, isTrue);
        expect(await service.requestPermissions(), isFalse);
        final permissionArguments = calls.last.arguments as Map;
        expect(permissionArguments['critical'], isFalse);
        handler = null;
        await service.showChatNotification(
          model: const ChatNotificationModel(
            id: 1,
            title: 'Chat',
            body: 'Hi',
            userImageUrl: null,
            userName: 'Alex',
          ),
        );
        expect(calls.last.method, 'show');
        expect(service.supportsChatNotifications, isFalse);
      },
    );
  }

  test('Linux initializes, displays and cancels through one plugin', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final linux = _LinuxPlugin();
    FlutterLocalNotificationsPlatform.instance = linux;
    final launchAction = service.actionStream.first;
    await initialize(
      data: const NotificationData(
        initializationSettingsLinux: LinuxInitializationSettings(
          defaultActionName: 'View',
        ),
      ),
    );
    expect(linux.settings?.defaultActionName, 'View');
    expect((await launchAction).payload, 'linux-launch');
    expect(await service.requestPermissions(), isTrue);
    await service.showNotification(
      model: const NotificationModel(
        id: 7,
        title: 'Title',
        body: 'Body',
        payload: 'chat-7',
      ),
    );
    expect(linux.payload, 'chat-7');
    expect(linux.details, isNotNull);
    await service.cancelNotification(7);
    expect(linux.cancelledId, 7);
    await service.cancelAllNotifications();
    expect(linux.cancelledAll, isTrue);
  });

  test('unsupported platforms fail explicitly', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    await expectLater(initialize(), throwsUnsupportedError);
    expect(service.isInitialized, isFalse);
  });

  test('action cancellation errors do not escape the callback', () async {
    await initialize();
    handler = (call) async {
      if (call.method == 'cancel') throw PlatformException(code: 'cancel');
      return null;
    };
    final action = service.actionStream.first;
    await sendResponse(actionId: NotificationConstants.replyActionId);
    expect(await action, isA<NotificationReplyAction>());
  });

  test('cancel preserves Android tags', () async {
    await initialize();
    await service.cancelNotification(7, tag: 'chat');
    expect(calls.last.arguments, {'id': 7, 'tag': 'chat'});
    await service.cancelAllNotifications();
    expect(calls.last.method, 'cancelAll');
  });

  test(
    'Windows uses the native plugin for payloads, launch, and cancellation',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final windows = _WindowsPlugin();
      FlutterLocalNotificationsPlatform.instance = windows;
      await initialize();
      expect(await service.requestPermissions(), isTrue);
      expect(
        (await service.appLaunchNotification)?.didNotificationLaunchApp,
        isFalse,
      );
      final settings = windows.settings!;
      expect(settings.appName, 'Test App');
      expect(
        settings.guid,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}$',
          ),
        ),
      );
      const model = NotificationModel(
        id: 7,
        title: 'Title',
        body: 'Body',
        payload: 'chat-7',
      );
      await service.showNotification(model: model);
      expect(windows.payload, 'chat-7');
      final action = service.actionStream.first;
      windows.onResponse!(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 7,
          payload: 'chat-7',
        ),
      );
      expect((await action).payload, 'chat-7');
      await service.showNotification(model: model);
      expect(windows.shownIds, [7, 7]);
      await service.cancelNotification(7);
      expect(windows.cancelledId, 7);
      await service.cancelAllNotifications();
      expect(windows.cancelledAll, isTrue);
      service.dispose();
      expect(windows.disposed, isTrue);
      await initialize();
      expect(windows.settings?.guid, settings.guid);
      expect(windows.settings?.appUserModelId, settings.appUserModelId);
      expect(calls, isEmpty);
    },
  );

  test('Windows accepts an explicit application identity', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final windows = _WindowsPlugin();
    FlutterLocalNotificationsPlatform.instance = windows;
    const identity = WindowsInitializationSettings(
      appName: 'Production App',
      appUserModelId: 'Company.Product',
      guid: '90e6574b-9b6f-4d90-b232-e6aed1bf707b',
    );
    await initialize(
      data: const NotificationData(initializationSettingsWindows: identity),
    );
    expect(windows.settings, same(identity));
    expect(
      const NotificationData(initializationSettingsWindows: identity)
          .copyWith()
          .initializationSettingsWindows,
      same(identity),
    );
  });
}

class _LinuxPlugin extends FlutterLocalNotificationsPlatform
    implements LinuxFlutterLocalNotificationsPlugin {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  LinuxInitializationSettings? settings;
  LinuxNotificationDetails? details;
  String? payload;
  int? cancelledId;
  bool cancelledAll = false;

  @override
  Future<bool?> initialize({
    required LinuxInitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) async {
    this.settings = settings;
    onDidReceiveNotificationResponse?.call(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'linux-launch',
      ),
    );
    return true;
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    LinuxNotificationDetails? notificationDetails,
    String? payload,
  }) async {
    details = notificationDetails;
    this.payload = payload;
  }

  @override
  Future<void> cancel({required int id}) async {
    cancelledId = id;
  }

  @override
  Future<void> cancelAll() async {
    cancelledAll = true;
  }
}

class _WindowsPlugin extends FlutterLocalNotificationsPlatform
    implements FlutterLocalNotificationsWindows {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  WindowsInitializationSettings? settings;
  DidReceiveNotificationResponseCallback? onResponse;
  String? payload;
  final shownIds = <int>[];
  int? cancelledId;
  bool cancelledAll = false;
  bool disposed = false;

  @override
  Future<bool> initialize({
    required WindowsInitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) async {
    this.settings = settings;
    onResponse = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    String? payload,
    WindowsNotificationDetails? notificationDetails,
  }) async {
    shownIds.add(id);
    this.payload = payload;
  }

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async =>
      const NotificationAppLaunchDetails(false);

  @override
  Future<void> cancel({required int id}) async {
    cancelledId = id;
  }

  @override
  Future<void> cancelAll() async {
    cancelledAll = true;
  }

  @override
  Future<void> periodicallyShow({
    required int id,
    String? title,
    String? body,
    required RepeatInterval repeatInterval,
    String? payload,
    WindowsNotificationDetails? notificationDetails,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required Object scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    WindowsNotificationDetails? notificationDetails,
  }) async {
    throw UnimplementedError();
  }

  @override
  void dispose() {
    disposed = true;
  }
}
