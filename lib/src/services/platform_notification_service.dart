import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:quick_notify_2/quick_notify.dart';

import '../constants/notification_constants.dart';
import '../models/notification_actions.dart';
import '../models/notification_data.dart';
import '../models/notification_models.dart';
import '../types/platform_types.dart';

/// Main service for handling cross-platform local notifications
class PlatformNotificationService {
  PlatformNotificationService._();

  static final _instance = PlatformNotificationService._();

  /// Singleton instance of the service
  static PlatformNotificationService get instance => _instance;

  /// Flutter local notifications plugin instance
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Stream controller for notification actions
  final _actionStreamController =
      StreamController<BaseNotificationAction>.broadcast();

  /// Receive port for isolate communication
  final _receivePort = ReceivePort();

  /// Application name
  late String _appName;

  /// Notification configuration data
  NotificationData? _notificationData;

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// Stream for listening to notification actions
  Stream<BaseNotificationAction> get actionStream =>
      _actionStreamController.stream;

  /// Returns true if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Returns true if running on web
  bool get isWeb => PlatformUtils.isWeb;

  /// Returns true if running on mobile platforms
  bool get isMobile => PlatformUtils.isMobile;

  /// Returns true if running on desktop platforms
  bool get isDesktop => PlatformUtils.isDesktop;

  /// Returns true if the current platform supports chat notifications
  bool get supportsChatNotifications => PlatformUtils.supportsChatNotifications;

  /// Returns true if the current platform supports notification actions
  bool get supportsNotificationActions =>
      PlatformUtils.supportsNotificationActions;

  /// Gets notification app launch details
  /// Returns details about how the app was launched (e.g., from notification click)
  Future<NotificationAppLaunchDetails?> get appLaunchNotification =>
      _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  /// Initializes the notification service
  ///
  /// [appName] - The name of the application
  /// [notificationData] - Configuration data for notifications
  Future<void> initialize({
    required String appName,
    NotificationData notificationData = const NotificationData(),
  }) async {
    _appName = appName;
    _notificationData = notificationData;
    if (_isInitialized) {
      debugPrint('PlatformNotificationService is already initialized');
      return;
    }

    if (isWeb) {
      _isInitialized = true;
      return;
    }

    try {
      if (isMobile) {
        await _initializeMobilePlatform();
      } else {
        await _initializeDesktopPlatform();
      }

      _isInitialized = true;
      debugPrint('PlatformNotificationService initialized successfully');
    } catch (error) {
      debugPrint('Failed to initialize PlatformNotificationService: $error');
      rethrow;
    }
  }

  /// Initializes the service for mobile platforms (Android/iOS)
  Future<void> _initializeMobilePlatform() async {
    try {
      if (Platform.isAndroid) {
        await _createAndroidNotificationChannel();
      }
    } catch (error) {
      debugPrint('Failed to create Android notification channel: $error');
    }

    await _flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: _notificationData!.initializationSettingsAndroid,
        iOS: _notificationData!.initializationSettingsDarwin,
      ),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    _setupActionPortReceiver();
  }

  /// Creates Android notification channel
  Future<void> _createAndroidNotificationChannel() async {
    final androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
        _notificationData!.androidNotificationChannel);
  }

  /// Initializes the service for desktop platforms (Windows/macOS/Linux)
  Future<void> _initializeDesktopPlatform() async {
    await localNotifier.setup(
      appName: _appName,
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  /// Sets up the action port receiver for isolate communication
  void _setupActionPortReceiver() {
    IsolateNameServer.registerPortWithName(
      _receivePort.sendPort,
      NotificationConstants.actionReceiverPortName,
    );

    _receivePort.listen(_handlePortMessage);
  }

  /// Handles messages from the isolate port
  void _handlePortMessage(dynamic data) {
    if (data is! List || data.length < 2) return;

    final isInput = data[0] as bool;
    final payload = data[1] as String?;

    if (isInput && data.length >= 3) {
      final text = data[2] as String;
      _actionStreamController.add(
        NotificationReplyAction(
          payload: payload,
          replyText: text,
        ),
      );
    } else {
      _actionStreamController.add(
        NotificationMarkReadAction(payload),
      );
    }
  }

  /// Requests notification permissions for the current platform
  Future<bool?> requestPermissions() async {
    if (!_isInitialized) {
      throw StateError(
          'PlatformNotificationService must be initialized before requesting permissions');
    }

    if (isWeb || Platform.isWindows) {
      return QuickNotify.requestPermission();
    }

    if (Platform.isIOS) {
      return await _requestIOSPermissions();
    }

    if (Platform.isAndroid) {
      return await _requestAndroidPermissions();
    }

    if (Platform.isMacOS) {
      return await _requestMacOSPermissions();
    }

    return false;
  }

  /// Requests iOS notification permissions
  Future<bool?> _requestIOSPermissions() async {
    final iosPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    return await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      critical: true,
      sound: true,
    );
  }

  /// Requests Android notification permissions
  Future<bool?> _requestAndroidPermissions() async {
    final androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    return await androidPlugin?.requestNotificationsPermission();
  }

  /// Requests macOS notification permissions
  Future<bool?> _requestMacOSPermissions() async {
    final macosPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();

    return await macosPlugin?.requestPermissions(
      alert: true,
      critical: true,
      badge: true,
      sound: true,
    );
  }

  /// Shows a standard notification
  Future<void> showNotification({
    required NotificationModel model,
    BuildContext? context,
  }) async {
    if (!_isInitialized) {
      throw StateError(
          'PlatformNotificationService must be initialized before showing notifications');
    }

    if (isWeb && context != null) {
      return _showWebNotification(model, context);
    }

    if (isMobile || Platform.isMacOS || Platform.isLinux) {
      await _showMobileNotification(model);
    }

    if (Platform.isWindows) {
      await _showWindowsNotification(model);
    }
  }

  /// Shows a chat-style notification with interactive actions
  Future<void> showChatNotification({
    required ChatNotificationModel model,
    BuildContext? context,
  }) async {
    if (!_isInitialized) {
      throw StateError(
          'PlatformNotificationService must be initialized before showing notifications');
    }

    if (!supportsChatNotifications) {
      return showNotification(model: model, context: context);
    }

    final userImageFile = await _loadUserImage(model.userImageUrl);
    final messagingStyle = _createMessagingStyle(model, userImageFile);

    final chatModel = model.copyWith(
      androidDetails: _createChatAndroidDetails(messagingStyle, model),
    );

    return showNotification(model: chatModel, context: null);
  }

  /// Loads user image from URL or cache
  Future<File?> _loadUserImage(String imageUrl) async {
    try {
      return await DefaultCacheManager().getSingleFile(imageUrl);
    } catch (error) {
      debugPrint('Failed to load user image: $error');
      return null;
    }
  }

  /// Creates messaging style for chat notifications
  MessagingStyleInformation _createMessagingStyle(
    ChatNotificationModel model,
    File? userImageFile,
  ) {
    return MessagingStyleInformation(
      Person(
        important: true,
        name: model.userName,
        icon: userImageFile != null
            ? BitmapFilePathAndroidIcon(userImageFile.path)
            : null,
      ),
      conversationTitle: model.conversationTitle,
      groupConversation: model.conversationTitle != null,
      messages: model.messages ??
          [
            Message(
              model.body,
              DateTime.now().toLocal(),
              Person(
                important: true,
                name: model.userName,
                icon: userImageFile != null
                    ? BitmapFilePathAndroidIcon(userImageFile.path)
                    : null,
              ),
            ),
          ],
    );
  }

  /// Creates Android notification details for chat notifications
  AndroidNotificationDetails _createChatAndroidDetails(
    MessagingStyleInformation messagingStyle,
    ChatNotificationModel model,
  ) {
    return AndroidNotificationDetails(
      model.androidDetails?.channelId ?? '${_appName}_chat_notification',
      model.androidDetails?.channelName ?? '${_appName}_chat_notification',
      channelDescription: model.androidDetails?.channelDescription ??
          '${_appName}_chat_notification_channel',
      styleInformation: messagingStyle,
      actions: [
        AndroidNotificationAction(
          NotificationConstants.markAsReadActionId,
          model.markAsReadLabel,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationConstants.replyActionId,
          model.replyLabel,
          allowGeneratedReplies: true,
          inputs: [
            AndroidNotificationActionInput(
              label: model.replyHint,
            ),
          ],
        ),
      ],
      importance: Importance.max,
      priority: Priority.max,
      setAsGroupSummary: true,
    );
  }

  /// Shows notification on mobile platforms
  Future<void> _showMobileNotification(NotificationModel model) async {
    final androidDetails = model.androidDetails ?? _getDefaultAndroidDetails();
    final iosDetails = model.iosDetails ?? _getDefaultIOSDetails();
    final macosDetails = model.macOsDetails ?? _getDefaultMacOSDetails();

    await _flutterLocalNotificationsPlugin.show(
      model.id,
      model.title,
      model.body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: macosDetails,
        linux: model.linuxDetails,
      ),
      payload: model.payload,
    );
  }

  /// Shows notification on Windows
  Future<void> _showWindowsNotification(NotificationModel model) async {
    await QuickNotify.notify(
      title: model.title,
      content: model.body,
    );
  }

  /// Shows notification on web
  void _showWebNotification(NotificationModel model, BuildContext? context) {
    QuickNotify.notify(
      title: model.title,
      content: model.body,
    );
  }

  /// Gets default Android notification details
  AndroidNotificationDetails _getDefaultAndroidDetails() {
    return AndroidNotificationDetails(
      '${_appName}_notification',
      '${_appName}_notification',
      channelDescription: '${_appName}_notification_channel',
      importance: Importance.max,
      priority: Priority.max,
      setAsGroupSummary: true,
    );
  }

  /// Gets default iOS notification details
  DarwinNotificationDetails _getDefaultIOSDetails() {
    return const DarwinNotificationDetails(
      badgeNumber: NotificationConstants.defaultBadgeNumber,
      presentSound: true,
      presentBadge: true,
    );
  }

  /// Gets default macOS notification details
  DarwinNotificationDetails _getDefaultMacOSDetails() {
    return DarwinNotificationDetails(
      presentSound: true,
      subtitle: _appName,
      presentBadge: true,
    );
  }

  /// Cancels a specific notification
  Future<void> cancelNotification(int id, {String? tag}) async {
    if (!_isInitialized) {
      throw StateError(
          'PlatformNotificationService must be initialized before canceling notifications');
    }

    await _flutterLocalNotificationsPlugin.cancel(id, tag: tag);
  }

  /// Cancels all notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) {
      throw StateError(
          'PlatformNotificationService must be initialized before canceling notifications');
    }

    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Handles notification response
  void _handleNotificationResponse(NotificationResponse response) {
    switch (response.notificationResponseType) {
      case NotificationResponseType.selectedNotification:
        _actionStreamController.add(
          NotificationClickAction(response.payload),
        );
        break;
      case NotificationResponseType.selectedNotificationAction:
        // Handled in background response
        break;
    }
  }

  /// Disposes the service and cleans up resources
  void dispose() {
    if (!_isInitialized) return;

    IsolateNameServer.removePortNameMapping(
      NotificationConstants.actionReceiverPortName,
    );
    _actionStreamController.close();
    _receivePort.close();
    _isInitialized = false;
  }
}

/// Global instance for easier access
///
/// Example usage:
/// ```dart
/// await PlatformNotifier.initialize(appName: 'My App');
/// await PlatformNotifier.showNotification(model: notificationModel);
/// ```
class PlatformNotifier {
  const PlatformNotifier._();

  /// The singleton instance of the notification service
  static PlatformNotificationService get instance =>
      PlatformNotificationService.instance;

  /// Stream for listening to notification actions
  static Stream<BaseNotificationAction> get actionStream =>
      instance.actionStream;

  /// Initializes the notification service
  static Future<void> initialize({
    required String appName,
    NotificationData notificationData = const NotificationData(),
  }) =>
      instance.initialize(appName: appName, notificationData: notificationData);

  /// Requests notification permissions
  static Future<bool?> requestPermissions() => instance.requestPermissions();

  /// Shows a standard notification
  static Future<void> showNotification({
    required NotificationModel model,
    BuildContext? context,
  }) =>
      instance.showNotification(model: model, context: context);

  /// Shows a chat-style notification
  static Future<void> showChatNotification({
    required ChatNotificationModel model,
    BuildContext? context,
  }) =>
      instance.showChatNotification(model: model, context: context);

  /// Cancels a specific notification
  static Future<void> cancelNotification(int id, {String? tag}) =>
      instance.cancelNotification(id, tag: tag);

  /// Cancels all notifications
  static Future<void> cancelAllNotifications() =>
      instance.cancelAllNotifications();

  /// Gets notification app launch details
  /// Returns details about how the app was launched (e.g., from notification click)
  static Future<NotificationAppLaunchDetails?> get appLaunchNotification =>
      instance.appLaunchNotification;

  /// Disposes the service
  static void dispose() => instance.dispose();
}

// Top-level functions for background notification handling

/// Handles background notification response
/// This function must be top-level for proper isolate communication
@pragma('vm:entry-point')
Future<void> onDidReceiveBackgroundNotificationResponse(
    NotificationResponse response) async {
  final sendPort = IsolateNameServer.lookupPortByName(
    NotificationConstants.actionReceiverPortName,
  );

  if (sendPort == null) return;

  if (response.actionId == NotificationConstants.markAsReadActionId) {
    sendPort.send([false, response.payload]);
  } else if (response.actionId == NotificationConstants.replyActionId) {
    final payload = response.payload.toString();
    final text = response.input.toString();

    sendPort.send([false, response.payload]);
    sendPort.send([true, payload, text]);
  }
}
