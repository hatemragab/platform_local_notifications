
import '../../platform_local_notifications.dart';

/// Configuration data for the notification plugin
class NotificationData {
  /// Android notification channel configuration
  final AndroidNotificationChannel androidNotificationChannel;

  /// Android initialization settings
  final AndroidInitializationSettings initializationSettingsAndroid;

  /// iOS/macOS initialization settings
  final DarwinInitializationSettings initializationSettingsDarwin;

  /// Creates notification data with default values
  const NotificationData({
    this.androidNotificationChannel = const AndroidNotificationChannel(
      NotificationConstants.defaultChannelId,
      NotificationConstants.defaultChannelDescription,
      importance: Importance.max,
    ),
    this.initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher'),
    this.initializationSettingsDarwin = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    ),
  });

  /// Creates a copy of this data with the given fields replaced
  NotificationData copyWith({
    AndroidNotificationChannel? androidNotificationChannel,
    AndroidInitializationSettings? initializationSettingsAndroid,
    DarwinInitializationSettings? initializationSettingsDarwin,
  }) {
    return NotificationData(
      androidNotificationChannel:
          androidNotificationChannel ?? this.androidNotificationChannel,
      initializationSettingsAndroid:
          initializationSettingsAndroid ?? this.initializationSettingsAndroid,
      initializationSettingsDarwin:
          initializationSettingsDarwin ?? this.initializationSettingsDarwin,
    );
  }
}
