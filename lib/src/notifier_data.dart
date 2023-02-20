import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotifierData {
  final AndroidNotificationChannel androidNotificationChannel;
  final AndroidInitializationSettings initializationSettingsAndroid;
  final DarwinInitializationSettings initializationSettingsDarwom;

  const NotifierData({
    this.androidNotificationChannel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      importance: Importance.max,
    ),
    this.initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher'),
    this.initializationSettingsDarwom = const DarwinInitializationSettings(),
  });
}

class ShowPluginNotificationModel {
  final int id;
  final String title;
  final String body;
  AndroidNotificationDetails? androidNotificationDetails;
  DarwinNotificationDetails? macOsDetails;
  final LinuxNotificationDetails? linux;
  DarwinNotificationDetails? iosDetails;
  final String? payload;

  ShowPluginNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.androidNotificationDetails,
    this.iosDetails,
    this.linux,
    this.macOsDetails,
    this.payload,
  });
}

abstract class BasePluginNotificationAction {}

class PluginNotificationClickAction extends BasePluginNotificationAction {
  final String? payload;

  PluginNotificationClickAction(this.payload);

  @override
  String toString() {
    return 'PluginNotificationClickAction{payload: $payload}';
  }
}

class PluginNotificationReplyAction extends BasePluginNotificationAction {
  final String text;
  final String? payload;
  PluginNotificationReplyAction(this.text, this.payload);

  @override
  String toString() {
    return 'PluginNotificationReplyAction{text: $text, payload: $payload}';
  }
}

class PluginNotificationMarkRead extends BasePluginNotificationAction {
  @override
  String toString() {
    return 'PluginNotificationMarkRead{}';
  }
}
