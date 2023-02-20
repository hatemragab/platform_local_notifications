import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:overlay_support/overlay_support.dart';
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
  late String appName;
  late final NotifierData data;

  InitializationSettings get initializationSettings => InitializationSettings(
        android: data.initializationSettingsAndroid,
        iOS: data.initializationSettingsDarwom,
      );

  Future<void> init({
    NotifierData data = const NotifierData(),
    required String appName,
  }) async {
    this.appName = appName;
    this.data = data;
    if (isWeb) {
      return;
    }
    if (isMobile) {
      await _initForMobile();
    } else {
      await _initForDesktop();
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
    try {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(data.androidNotificationChannel);
    } catch (err) {
      //
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
    IsolateNameServer.registerPortWithName(
      _port.sendPort,
      _portName,
    );
    _port.listen((var data) async {
      print(" ");
      final isInput = data[0] as bool;
      final payload = data[1] as String?;

      if (isInput) {
        final text = data[2] as String;
        _platformNotifierStream.sink
            .add(PluginNotificationReplyAction(text, payload));
      } else {
        _platformNotifierStream.sink.add(PluginNotificationMarkRead());
      }
    });
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancel(int id, {String? tag}) async {
    await flutterLocalNotificationsPlugin.cancel(id, tag: tag);
  }

  Future<void> _initForDesktop() async {
    await localNotifier.setup(
      appName: appName,
      // The parameter shortcutPolicy only works on Windows
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  Future<void> showChatNotification({
    required ShowPluginNotificationModel model,
    required String userImage,
    String makeAsRead = "Make as read",
    String reply = "Reply",
    String yourMessage = "Your message...",

    ///user name in the icon person!
    required String userName,
    List<Message>? messages,

    ///for group chat
    required String? conversationTitle,
  }) async {
    if (isWeb || isDesktop) {
      return showPluginNotification(model);
    }
    File? file;
    try {
      file = await DefaultCacheManager().getSingleFile(userImage);
    } catch (err) {
      print(err);

      ///
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
    return showPluginNotification(model);
  }

  AndroidNotificationDetails get _highAndroidNotificationDetails =>
      AndroidNotificationDetails(
        "${appName}_notification",
        "${appName}_notification",
        channelDescription: "${appName}_notification_channel",
        importance: Importance.max,
        priority: Priority.max,
        setAsGroupSummary: true,
      );

  AndroidNotificationDetails _highAndroidNotificationChatDetails({
    required MessagingStyleInformation styleInformation,
    AndroidNotificationDetails? androidNotificationDetails,
    String makeAsRead = "Make as read",
    String reply = "Reply",
    String yourMessage = "Your message...",
  }) =>
      AndroidNotificationDetails(
        "${appName}_notification",
        "${appName}_notification",
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
        channelDescription: "${appName}_notification_channel",
        importance: Importance.max,
        priority: Priority.max,
        setAsGroupSummary: true,
      );

  DarwinNotificationDetails get _highDarwinNotificationDetails =>
      const DarwinNotificationDetails(
        badgeNumber: 1,
        presentSound: true,
        presentBadge: true,
      );

  Future<void> showPluginNotification(
    ShowPluginNotificationModel model,
  ) async {
    model.androidNotificationDetails ??= _highAndroidNotificationDetails;
    model.iosDetails ??= _highDarwinNotificationDetails;

    if (isWeb) {
      return _showOverlaySupport(title: model.title, subtitle: model.body);
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
                subtitle: appName,
                presentBadge: true,
              ),
          linux: model.linux,
        ),
        payload: model.payload,
      );
    } else if (Platform.isWindows) {
      final notification = LocalNotification(
        title: appName,
        subtitle: model.title,
        identifier: model.payload,
        body: model.body,
      );
      await localNotifier.notify(notification);
      //  await notification.show();
      notification.onClick = () {
        _platformNotifierStream.sink
            .add(PluginNotificationClickAction(notification.identifier));
      };
    }
  }

  void close() {
    IsolateNameServer.removePortNameMapping(_portName);
    _platformNotifierStream.close();
  }

  void _showOverlaySupport({
    Duration duration = const Duration(seconds: 5),
    String? subtitle,
    required String title,
    TextStyle? textStyle,
    Color? background,
  }) {
    showSimpleNotification(
      Text(title, style: textStyle),
      background: background,
      autoDismiss: true,
      slideDismissDirection: DismissDirection.horizontal,
      subtitle: subtitle == null ? null : Text(subtitle),
      duration: duration,
    );
  }

  @pragma('vm:entry-point')
  void _onDidReceiveNotificationResponse(NotificationResponse details) {
    switch (details.notificationResponseType) {
      case NotificationResponseType.selectedNotification:
        _platformNotifierStream.sink
            .add(PluginNotificationClickAction(details.payload));
        break;
      case NotificationResponseType.selectedNotificationAction:
        break;
    }
  }

  Future<bool?> requestPermissions() async {
    if (kIsWeb) return false;
    if (Platform.isIOS) {
      return await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      return await androidImplementation?.requestPermission();
    } else if (Platform.isMacOS) {
      return await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
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
  if (event.actionId == "1") {
    final SendPort? send = IsolateNameServer.lookupPortByName(_portName);
    send!.send([false, event.payload]);
    _platformNotifierStream.sink.add(PluginNotificationMarkRead());
  }
  if (event.actionId == "2") {
    final payload = event.payload.toString();
    final text = event.input.toString();
    final SendPort? send = IsolateNameServer.lookupPortByName(_portName);
    send!.send([false, event.payload]);
    send.send([true, payload, text]);
    _platformNotifierStream.sink
        .add(PluginNotificationReplyAction(text, payload));
    _platformNotifierStream.sink.add(PluginNotificationMarkRead());
  }
}
