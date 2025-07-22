
import '../../platform_local_notifications.dart';

/// Configuration data for the notification plugin
class NotificationConfiguration {
  /// Android notification channel configuration
  final AndroidNotificationChannel androidChannel;

  /// Android initialization settings
  final AndroidInitializationSettings androidSettings;

  /// iOS/macOS initialization settings
  final DarwinInitializationSettings darwinSettings;

  /// Creates notification configuration with default values
  const NotificationConfiguration({
    this.androidChannel = const AndroidNotificationChannel(
      NotificationConstants.defaultChannelId,
      NotificationConstants.defaultChannelDescription,
      importance: Importance.max,
    ),
    this.androidSettings =
        const AndroidInitializationSettings('@mipmap/ic_launcher'),
    this.darwinSettings = const DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      requestCriticalPermission: false,
    ),
  });

  /// Creates a copy of this configuration with the given fields replaced
  NotificationConfiguration copyWith({
    AndroidNotificationChannel? androidChannel,
    AndroidInitializationSettings? androidSettings,
    DarwinInitializationSettings? darwinSettings,
  }) {
    return NotificationConfiguration(
      androidChannel: androidChannel ?? this.androidChannel,
      androidSettings: androidSettings ?? this.androidSettings,
      darwinSettings: darwinSettings ?? this.darwinSettings,
    );
  }
}

/// Model for showing a notification
class NotificationModel {
  /// Unique identifier for the notification
  final int id;

  /// Notification title
  final String title;

  /// Notification body/content
  final String body;

  /// Optional payload data
  final String? payload;

  /// Android-specific notification details
  final AndroidNotificationDetails? androidDetails;

  /// iOS-specific notification details
  final DarwinNotificationDetails? iosDetails;

  /// macOS-specific notification details
  final DarwinNotificationDetails? macOsDetails;

  /// Linux-specific notification details
  final LinuxNotificationDetails? linuxDetails;

  /// Creates a notification model
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
    this.androidDetails,
    this.iosDetails,
    this.macOsDetails,
    this.linuxDetails,
  });

  /// Creates a copy of this model with the given fields replaced
  NotificationModel copyWith({
    int? id,
    String? title,
    String? body,
    String? payload,
    AndroidNotificationDetails? androidDetails,
    DarwinNotificationDetails? iosDetails,
    DarwinNotificationDetails? macOsDetails,
    LinuxNotificationDetails? linuxDetails,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      androidDetails: androidDetails ?? this.androidDetails,
      iosDetails: iosDetails ?? this.iosDetails,
      macOsDetails: macOsDetails ?? this.macOsDetails,
      linuxDetails: linuxDetails ?? this.linuxDetails,
    );
  }
}

/// Model for chat-style notifications
class ChatNotificationModel extends NotificationModel {
  /// URL or path to the user's profile image
  final String userImageUrl;

  /// Name of the user sending the message
  final String userName;

  /// Title of the conversation (for group chats)
  final String? conversationTitle;

  /// List of messages in the conversation
  final List<Message>? messages;

  /// Label for the "mark as read" action
  final String markAsReadLabel;

  /// Label for the "reply" action
  final String replyLabel;

  /// Hint text for the reply input field
  final String replyHint;

  /// Creates a chat notification model
  const ChatNotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required this.userImageUrl,
    required this.userName,
    super.payload,
    this.conversationTitle,
    this.messages,
    this.markAsReadLabel = 'Mark as read',
    this.replyLabel = 'Reply',
    this.replyHint = 'Your message...',
    super.androidDetails,
    super.iosDetails,
    super.macOsDetails,
    super.linuxDetails,
  });

  @override
  ChatNotificationModel copyWith({
    int? id,
    String? title,
    String? body,
    String? userImageUrl,
    String? userName,
    String? conversationTitle,
    List<Message>? messages,
    String? markAsReadLabel,
    String? replyLabel,
    String? replyHint,
    String? payload,
    AndroidNotificationDetails? androidDetails,
    DarwinNotificationDetails? iosDetails,
    DarwinNotificationDetails? macOsDetails,
    LinuxNotificationDetails? linuxDetails,
  }) {
    return ChatNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      userImageUrl: userImageUrl ?? this.userImageUrl,
      userName: userName ?? this.userName,
      conversationTitle: conversationTitle ?? this.conversationTitle,
      messages: messages ?? this.messages,
      markAsReadLabel: markAsReadLabel ?? this.markAsReadLabel,
      replyLabel: replyLabel ?? this.replyLabel,
      replyHint: replyHint ?? this.replyHint,
      payload: payload ?? this.payload,
      androidDetails: androidDetails ?? this.androidDetails,
      iosDetails: iosDetails ?? this.iosDetails,
      macOsDetails: macOsDetails ?? this.macOsDetails,
      linuxDetails: linuxDetails ?? this.linuxDetails,
    );
  }
}
