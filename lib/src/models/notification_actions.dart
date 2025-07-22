/// Base class for all notification actions
abstract class BaseNotificationAction {
  /// The payload associated with the notification
  final String? payload;

  /// Creates a base notification action
  const BaseNotificationAction(this.payload);

  @override
  String toString() => 'BaseNotificationAction{payload: $payload}';
}

/// Action triggered when user clicks on a notification
class NotificationClickAction extends BaseNotificationAction {
  /// Creates a notification click action
  const NotificationClickAction(super.payload);

  @override
  String toString() => 'NotificationClickAction{payload: $payload}';
}

/// Action triggered when user replies to a notification
class NotificationReplyAction extends BaseNotificationAction {
  /// The reply text entered by the user
  final String replyText;

  /// Creates a notification reply action
  const NotificationReplyAction({
    required String? payload,
    required this.replyText,
  }) : super(payload);

  @override
  String toString() =>
      'NotificationReplyAction{replyText: $replyText, payload: $payload}';
}

/// Action triggered when user marks a notification as read
class NotificationMarkReadAction extends BaseNotificationAction {
  /// Creates a notification mark as read action
  const NotificationMarkReadAction(super.payload);

  @override
  String toString() => 'NotificationMarkReadAction{payload: $payload}';
}
