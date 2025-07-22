/// Constants used throughout the platform local notifications plugin
class NotificationConstants {
  const NotificationConstants._();

  /// Port name for isolate communication
  static const String actionReceiverPortName = 'v_action_receiver_port';

  /// Default notification channel ID
  static const String defaultChannelId = 'high_importance_channel';

  /// Default notification channel name
  static const String defaultChannelName = 'High Importance Notifications';

  /// Default notification channel description
  static const String defaultChannelDescription =
      'High importance notifications';

  /// Default action IDs
  static const String markAsReadActionId = '1';
  static const String replyActionId = '2';

  /// Default action labels
  static const String defaultMarkAsReadLabel = 'Mark as read';
  static const String defaultReplyLabel = 'Reply';
  static const String defaultReplyHint = 'Your message...';

  /// Default notification importance
  static const int defaultImportance = 4; // Importance.max

  /// Default notification priority
  static const int defaultPriority = 2; // Priority.max

  /// Default badge number
  static const int defaultBadgeNumber = 1;

  /// Default app icon path for Android
  static const String defaultAndroidIconPath = '@mipmap/ic_launcher';


}
