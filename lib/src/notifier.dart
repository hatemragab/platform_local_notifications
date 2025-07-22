import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:quick_notify_2/quick_notify.dart';

import '../platform_local_notifications.dart';

const _portName = "v_action_receiver_port";

final _platformNotifierStream =
    StreamController<BasePluginNotificationAction>.broadcast();

class PlatformNotifier {
  PlatformNotifier._();

  static final flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final _instance = PlatformNotifier._();
  final _port = ReceivePort();

  Stream<BasePluginNotificationAction> get platformNotifierStream =>
      _platformNotifierStream.stream;

  static PlatformNotifier get I => _instance;

  // Add initialization tracking
  bool _isInitialized = false;
  String? _appName;
  NotifierData? _data;

  // Safe getters with null checks
  bool get isInitialized => _isInitialized;

  String get appName {
    if (!_isInitialized || _appName == null) {
      throw StateError(
          'PlatformNotifier has not been initialized. Call init() first.');
    }
    return _appName!;
  }

  NotifierData get data {
    if (!_isInitialized || _data == null) {
      throw StateError(
          'PlatformNotifier has not been initialized. Call init() first.');
    }
    return _data!;
  }

  // Safe getters that return null instead of throwing
  String? get appNameSafe => _isInitialized ? _appName : null;

  NotifierData? get dataSafe => _isInitialized ? _data : null;

  InitializationSettings get initializationSettings {
    if (!_isInitialized) {
      throw StateError(
          'PlatformNotifier has not been initialized. Call init() first.');
    }
    return InitializationSettings(
      android: data.initializationSettingsAndroid,
      iOS: data.initializationSettingsDarwom,
    );
  }

  Future<void> init({
    NotifierData data = const NotifierData(),
    required String appName,
  }) async {
    try {
      _appName = appName;
      _data = data;

      if (isWeb) {
        _isInitialized = true;
        return;
      }

      if (isMobile) {
        await _initForMobile();
      } else {
        await _initForDesktop();
      }

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      if (kDebugMode) {
        print('Failed to initialize PlatformNotifier: $e');
      }
      rethrow;
    }
  }

  bool get isWeb => kIsWeb;

  bool get isMobile {
    if (isWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  bool get isDesktop {
    if (isWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  Future<void> _initForMobile() async {
    if (!_isInitialized || _data == null) {
      throw StateError('Cannot initialize mobile notifications: data not set');
    }

    try {
      if (Platform.isAndroid) {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_data!.androidNotificationChannel);
      }
    } catch (err) {
      if (kDebugMode) {
        print('Error creating notification channel: $err');
      }
    }

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    _initActionPortReceiver();
  }

  void _initActionPortReceiver() {
    try {
      IsolateNameServer.registerPortWithName(
        _port.sendPort,
        _portName,
      );
      _port.listen((var data) async {
        try {
          final isInput = data[0] as bool;
          final payload = data[1] as String?;

          if (isInput) {
            final text = data[2] as String;
            _platformNotifierStream.sink.add(
                PluginNotificationReplyAction(text: text, payload: payload));
          } else {
            _platformNotifierStream.sink
                .add(PluginNotificationMarkRead(payload));
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing action port data: $e');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up action port receiver: $e');
      }
    }
  }

  Future<void> cancelAll() async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
            'Warning: PlatformNotifier not initialized, cannot cancel notifications');
      }
      return;
    }
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancel(int id, {String? tag}) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
            'Warning: PlatformNotifier not initialized, cannot cancel notification');
      }
      return;
    }
    await flutterLocalNotificationsPlugin.cancel(id, tag: tag);
  }

  Future<void> _initForDesktop() async {
    if (_appName == null) {
      throw StateError('App name not set');
    }

    await localNotifier.setup(
      appName: _appName!,
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  Future<void> showChatNotification({
    required ShowPluginNotificationModel model,
    required String userImage,
    String makeAsRead = "Make as read",
    String reply = "Reply",
    String yourMessage = "Your message...",
    required String userName,
    List<Message>? messages,
    BuildContext? context,
    required String? conversationTitle,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
            'Warning: PlatformNotifier not initialized, cannot show chat notification');
      }
      return;
    }

    if (isWeb || isDesktop) {
      return showPluginNotification(model, context);
    }

    File? file;
    try {
      file = await DefaultCacheManager().getSingleFile(userImage);
    } catch (err) {
      if (kDebugMode) {
        print('Error loading user image: $err');
      }
    }

    final messagingStyleInformation = MessagingStyleInformation(
      Person(
        important: true,
        name: userName,
      ),
      conversationTitle: conversationTitle,
      groupConversation: true,
      messages: messages ??
          [
            Message(
              model.body,
              DateTime.now().toLocal(),
              Person(
                important: true,
                name: userName,
                icon:
                    file == null ? null : BitmapFilePathAndroidIcon(file.path),
              ),
            ),
          ],
    );

    model.androidNotificationDetails = _highAndroidNotificationChatDetails(
      styleInformation: messagingStyleInformation,
      androidNotificationDetails: model.androidNotificationDetails,
      makeAsRead: makeAsRead,
      reply: reply,
      yourMessage: yourMessage,
    );
    return showPluginNotification(model, context);
  }

  AndroidNotificationDetails get _highAndroidNotificationDetails {
    if (!_isInitialized || _appName == null) {
      throw StateError('PlatformNotifier not initialized');
    }
    return AndroidNotificationDetails(
      "${_appName!}_notification",
      "${_appName!}_notification",
      channelDescription: "${_appName!}_notification_channel",
      importance: Importance.max,
      priority: Priority.max,
      setAsGroupSummary: true,
    );
  }

  AndroidNotificationDetails _highAndroidNotificationChatDetails({
    required MessagingStyleInformation styleInformation,
    AndroidNotificationDetails? androidNotificationDetails,
    String makeAsRead = "Make as read",
    String reply = "Reply",
    String yourMessage = "Your message...",
  }) {
    if (!_isInitialized || _appName == null) {
      throw StateError('PlatformNotifier not initialized');
    }
    return AndroidNotificationDetails(
      "${_appName!}_notification",
      "${_appName!}_notification",
      styleInformation: styleInformation,
      actions: [
        AndroidNotificationAction(
          "1",
          makeAsRead,
        ),
        AndroidNotificationAction(
          "2",
          reply,
          allowGeneratedReplies: true,
          inputs: [
            AndroidNotificationActionInput(
              label: yourMessage,
            )
          ],
        ),
      ],
      channelDescription: "${_appName!}_notification_channel",
      importance: Importance.max,
      priority: Priority.max,
      setAsGroupSummary: true,
    );
  }

  /// Generates a group key for notification grouping
  static String _generateGroupKey(String roomId) {
    return 'chat_$roomId';
  }

  DarwinNotificationDetails get _highDarwinNotificationDetails =>
      const DarwinNotificationDetails(
        badgeNumber: 1,
        presentSound: true,
        presentBadge: true,
      );

  Future<void> showPluginNotification(
    ShowPluginNotificationModel model,
    BuildContext? context,
  ) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
            'Warning: PlatformNotifier not initialized, cannot show notification');
      }
      return;
    }

    model.androidNotificationDetails ??= _highAndroidNotificationDetails;
    model.iosDetails ??= _highDarwinNotificationDetails;

    if (isWeb && context != null) {
      return _showOverlaySupport(
        title: model.title,
        subtitle: model.body,
        context: context,
      );
    }

    if (isMobile || Platform.isMacOS || Platform.isLinux) {
      await flutterLocalNotificationsPlugin.show(
        model.id,
        model.title,
        model.body,
        NotificationDetails(
          android: model.androidNotificationDetails,
          iOS: model.iosDetails,
          macOS: model.macOsDetails ??
              DarwinNotificationDetails(
                presentSound: true,
                subtitle: _appName ?? 'App',
                presentBadge: true,
              ),
          linux: model.linux,
        ),
        payload: model.payload,
      );
    }
    if (Platform.isWindows) {
      await QuickNotify.notify(
        title: model.title,
        content: model.body,
      );
    }
  }

  void close() {
    try {
      IsolateNameServer.removePortNameMapping(_portName);
      _platformNotifierStream.close();
      _isInitialized = false;
    } catch (e) {
      if (kDebugMode) {
        print('Error closing PlatformNotifier: $e');
      }
    }
  }

  void _showOverlaySupport({
    required String subtitle,
    required String title,
    required BuildContext context,
  }) {
    QuickNotify.notify(
      title: title,
      content: subtitle,
    );
  }

  @pragma('vm:entry-point')
  void _onDidReceiveNotificationResponse(NotificationResponse details) {
    try {
      switch (details.notificationResponseType) {
        case NotificationResponseType.selectedNotification:
          _platformNotifierStream.sink
              .add(PluginNotificationClickAction(details.payload));
          break;
        case NotificationResponseType.selectedNotificationAction:
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling notification response: $e');
      }
    }
  }

  Future<bool?> requestPermissions() async {
    if (kIsWeb || Platform.isWindows) {
      return QuickNotify.requestPermission();
    }
    if (Platform.isIOS) {
      return await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            critical: true,
            sound: true,
          );
    }
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      return await androidImplementation?.requestNotificationsPermission();
    }
    if (Platform.isMacOS) {
      return await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            critical: true,
            badge: true,
            sound: true,
          );
    }

    return false;
  }
}

@pragma('vm:entry-point')
Future<void> onDidReceiveBackgroundNotificationResponse(
  NotificationResponse event,
) async {
  try {
    // Check if the notifier is initialized before accessing data
    if (!PlatformNotifier.I.isInitialized) {
      if (kDebugMode) {
        print(
            'Warning: PlatformNotifier not initialized in background handler');
      }
      return;
    }

    if (event.actionId == "1") {
      final SendPort? send = IsolateNameServer.lookupPortByName(_portName);
      if (send != null) {
        send.send([false, event.payload]);
        _platformNotifierStream.sink
            .add(PluginNotificationMarkRead(event.payload));
      }
    }
    if (event.actionId == "2") {
      final payload = event.payload.toString();
      final text = event.input.toString();
      final SendPort? send = IsolateNameServer.lookupPortByName(_portName);
      if (send != null) {
        send.send([false, event.payload]);
        send.send([true, payload, text]);
        _platformNotifierStream.sink
            .add(PluginNotificationReplyAction(text: text, payload: payload));
        _platformNotifierStream.sink.add(PluginNotificationMarkRead(payload));
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error in background notification handler: $e');
    }
  }
}
