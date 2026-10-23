import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/notification_constants.dart';

/// Configuration data for the notification plugin
class NotificationData {
  /// Android notification channel configuration
  final AndroidNotificationChannel androidNotificationChannel;

  /// Android initialization settings
  final AndroidInitializationSettings initializationSettingsAndroid;

  /// iOS/macOS initialization settings
  final DarwinInitializationSettings initializationSettingsDarwin;

  /// Linux initialization settings, including the default click action label.
  final LinuxInitializationSettings initializationSettingsLinux;

  /// Optional Windows application identity. If omitted, a stable identity is
  /// derived from the application name. Set this explicitly for production apps.
  final WindowsInitializationSettings? initializationSettingsWindows;

  /// Creates notification data with default values
  const NotificationData({
    this.initializationSettingsWindows,
    this.androidNotificationChannel = const AndroidNotificationChannel(
      NotificationConstants.defaultChannelId,
      NotificationConstants.defaultChannelName,
      description: NotificationConstants.defaultChannelDescription,
      importance: Importance.max,
    ),
    this.initializationSettingsAndroid = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    ),
    this.initializationSettingsDarwin = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    ),
    this.initializationSettingsLinux = const LinuxInitializationSettings(
      defaultActionName: 'Open',
    ),
  });

  /// Creates a copy of this data with the given fields replaced
  NotificationData copyWith({
    AndroidNotificationChannel? androidNotificationChannel,
    AndroidInitializationSettings? initializationSettingsAndroid,
    DarwinInitializationSettings? initializationSettingsDarwin,
    LinuxInitializationSettings? initializationSettingsLinux,
    WindowsInitializationSettings? initializationSettingsWindows,
  }) {
    return NotificationData(
      androidNotificationChannel:
          androidNotificationChannel ?? this.androidNotificationChannel,
      initializationSettingsAndroid:
          initializationSettingsAndroid ?? this.initializationSettingsAndroid,
      initializationSettingsDarwin:
          initializationSettingsDarwin ?? this.initializationSettingsDarwin,
      initializationSettingsLinux:
          initializationSettingsLinux ?? this.initializationSettingsLinux,
      initializationSettingsWindows:
          initializationSettingsWindows ?? this.initializationSettingsWindows,
    );
  }
}
