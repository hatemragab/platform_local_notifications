import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';

import '../constants/notification_constants.dart';
import '../models/notification_actions.dart';
import '../models/notification_data.dart';
import '../models/notification_models.dart';
import '../platform/native_support.dart';
import '../platform/web_notifications.dart';
import '../types/platform_types.dart';

/// Main service for handling cross-platform local notifications.
class PlatformNotificationService {
  PlatformNotificationService._();

  static final _instance = PlatformNotificationService._();

  /// Singleton instance of the service.
  static PlatformNotificationService get instance => _instance;

  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final _nativeSupport = NativeNotificationSupport();
  final _webBackend = WebNotificationBackend();
  // A fresh controller after disposal keeps the singleton reusable while
  // completing subscriptions associated with the previous lifecycle.
  var _actionStreamController =
      StreamController<BaseNotificationAction>.broadcast();
  NotificationData _notificationData = const NotificationData();
  String _appName = '';
  bool _isInitialized = false;
  Future<void>? _initialization;
  int _generation = 0;

  /// Stream for listening to notification actions.
  Stream<BaseNotificationAction> get actionStream =>
      _actionStreamController.stream;

  /// Returns true if the service is initialized.
  bool get isInitialized => _isInitialized;

  /// Returns true if running on web.
  bool get isWeb => PlatformUtils.isWeb;

  /// Returns true if running on mobile platforms.
  bool get isMobile => PlatformUtils.isMobile;

  /// Returns true if running on desktop platforms.
  bool get isDesktop => PlatformUtils.isDesktop;

  /// Whether built-in Android messaging style and chat actions are available.
  bool get supportsChatNotifications => PlatformUtils.supportsChatNotifications;

  /// Whether built-in reply and mark-as-read actions are available.
  bool get supportsNotificationActions =>
      PlatformUtils.supportsNotificationActions;

  /// Gets native notification launch details, or null on web.
  Future<NotificationAppLaunchDetails?> get appLaunchNotification async {
    _ensureInitialized();
    if (isWeb) {
      return null;
    }
    return _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  }

  /// Initializes the notification service. Concurrent calls share initialization;
  /// subsequent calls retain the configuration of the first successful call.
  Future<void> initialize({
    required String appName,
    NotificationData notificationData = const NotificationData(),
  }) {
    if (_isInitialized) return Future<void>.value();
    final pending = _initialization;
    if (pending != null) return pending;
    if (appName.trim().isEmpty) {
      return Future<void>.error(
        ArgumentError.value(appName, 'appName', 'Must not be blank'),
      );
    }
    final generation = _generation;
    _appName = appName;
    _notificationData = notificationData;
    final initialization = Future<void>.microtask(
      () => _initialize(generation),
    );
    _initialization = initialization;
    return initialization;
  }

  Future<void> _initialize(int generation) async {
    final pendingResponses = <NotificationResponse>[];
    void onResponse(NotificationResponse response) {
      if (generation != _generation) return;
      if (_isInitialized) {
        _handleNotificationResponse(response);
      } else {
        // Linux can report the launching notification during initialization.
        pendingResponses.add(response);
      }
    }

    try {
      if (generation != _generation) return;
      final platform = PlatformUtils.currentPlatform;
      if (platform == SupportedPlatform.unknown) {
        throw UnsupportedError(
          'Notifications are unavailable on this platform',
        );
      }
      if (!isWeb) {
        final initialized = await _flutterLocalNotificationsPlugin.initialize(
          settings: InitializationSettings(
            android: _notificationData.initializationSettingsAndroid,
            iOS: _notificationData.initializationSettingsDarwin,
            macOS: _notificationData.initializationSettingsDarwin,
            linux: _notificationData.initializationSettingsLinux,
            windows:
                _notificationData.initializationSettingsWindows ??
                _defaultWindowsSettings(),
          ),
          onDidReceiveNotificationResponse: onResponse,
          onDidReceiveBackgroundNotificationResponse:
              onDidReceiveBackgroundNotificationResponse,
        );
        // On Apple platforms this result reports permission, not setup success.
        if (initialized != true &&
            platform != SupportedPlatform.ios &&
            platform != SupportedPlatform.macos) {
          throw StateError('Native notification initialization failed');
        }
        if (generation != _generation) return;
        if (platform == SupportedPlatform.android) {
          await _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.createNotificationChannel(
                _notificationData.androidNotificationChannel,
              );
        }
        if (generation != _generation) return;
        if (isMobile) {
          _nativeSupport.startActionReceiver(onResponse);
        }
      }
      if (generation == _generation) {
        _isInitialized = true;
        for (final response in pendingResponses) {
          _handleNotificationResponse(response);
        }
        pendingResponses.clear();
      }
    } catch (_) {
      if (generation == _generation) _nativeSupport.dispose();
      rethrow;
    } finally {
      _initialization = null;
    }
  }

  WindowsInitializationSettings _defaultWindowsSettings() {
    final guid = const Uuid().v5(
      Namespace.url.value,
      'https://github.com/hatemragab/platform_local_notifications/apps/$_appName',
    );
    return WindowsInitializationSettings(
      appName: _appName,
      appUserModelId:
          'PlatformLocalNotifications.App.${guid.replaceAll('-', '')}',
      guid: guid,
    );
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'PlatformNotificationService must be initialized before use',
      );
    }
  }

  /// Requests standard notification permissions. Critical-alert entitlement is
  /// not requested automatically. Linux and Windows have no runtime prompt.
  Future<bool?> requestPermissions() async {
    _ensureInitialized();
    switch (PlatformUtils.currentPlatform) {
      case SupportedPlatform.web:
        return _webBackend.requestPermissions();
      case SupportedPlatform.android:
        return _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      case SupportedPlatform.ios:
        return _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      case SupportedPlatform.macos:
        return _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      case SupportedPlatform.windows:
      case SupportedPlatform.linux:
        return true;
      case SupportedPlatform.unknown:
        return false;
    }
  }

  /// Shows a notification. IDs must fit a signed 32-bit integer.
  Future<void> showNotification({required NotificationModel model}) async {
    _ensureInitialized();
    _validateModel(model);
    final generation = _generation;
    if (isWeb) {
      return _webBackend.show(model, () {
        if (_isInitialized && generation == _generation) {
          _actionStreamController.add(NotificationClickAction(model.payload));
        }
      });
    }
    await _flutterLocalNotificationsPlugin.show(
      id: model.id,
      title: model.title,
      body: model.body,
      notificationDetails: NotificationDetails(
        android: model.androidDetails ?? _defaultAndroidDetails(),
        iOS:
            model.iosDetails ??
            const DarwinNotificationDetails(
              badgeNumber: NotificationConstants.defaultBadgeNumber,
              presentSound: true,
              presentBadge: true,
            ),
        macOS:
            model.macOsDetails ??
            DarwinNotificationDetails(
              presentSound: true,
              subtitle: _appName,
              presentBadge: true,
            ),
        linux: model.linuxDetails ?? const LinuxNotificationDetails(),
      ),
      payload: model.payload,
    );
  }

  void _validateModel(NotificationModel model) {
    if (!model.isValid) {
      throw ArgumentError.value(
        model.id,
        'model.id',
        'Must fit a signed 32-bit integer',
      );
    }
  }

  /// Shows Android messaging style with reply and mark-as-read actions.
  /// Other platforms receive a standard notification with the same payload.
  Future<void> showChatNotification({
    required ChatNotificationModel model,
  }) async {
    _ensureInitialized();
    _validateModel(model);
    if (!supportsChatNotifications) return showNotification(model: model);
    final generation = _generation;
    final imagePath = await _nativeSupport.loadImage(model.userImageUrl);
    if (generation != _generation) {
      throw StateError('Notification service was disposed');
    }
    final sender = Person(
      important: true,
      name: model.userName,
      icon: imagePath == null ? null : BitmapFilePathAndroidIcon(imagePath),
    );
    final style = MessagingStyleInformation(
      sender,
      conversationTitle: model.conversationTitle,
      groupConversation: model.conversationTitle != null,
      messages: model.messages ?? [Message(model.body, DateTime.now(), sender)],
    );
    final details = model.androidDetails;
    final channel = _notificationData.androidNotificationChannel;
    return showNotification(
      model: model.copyWith(
        androidDetails: AndroidNotificationDetails(
          details?.channelId ?? channel.id,
          details?.channelName ?? channel.name,
          channelDescription:
              details?.channelDescription ?? channel.description,
          icon: details?.icon,
          importance: details?.importance ?? channel.importance,
          priority: details?.priority ?? Priority.max,
          playSound: details?.playSound ?? channel.playSound,
          sound: details?.sound ?? channel.sound,
          enableVibration: details?.enableVibration ?? channel.enableVibration,
          vibrationPattern:
              details?.vibrationPattern ?? channel.vibrationPattern,
          groupKey: details?.groupKey,
          tag: details?.tag,
          color: details?.color,
          styleInformation: style,
          actions: [
            AndroidNotificationAction(
              NotificationConstants.markAsReadActionId,
              model.markAsReadLabel,
            ),
            AndroidNotificationAction(
              NotificationConstants.replyActionId,
              model.replyLabel,
              inputs: [AndroidNotificationActionInput(label: model.replyHint)],
            ),
          ],
        ),
      ),
    );
  }

  AndroidNotificationDetails _defaultAndroidDetails() {
    final channel = _notificationData.androidNotificationChannel;
    return AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: Priority.max,
      playSound: channel.playSound,
      sound: channel.sound,
      enableVibration: channel.enableVibration,
      vibrationPattern: channel.vibrationPattern,
      enableLights: channel.enableLights,
      ledColor: channel.ledColor,
      channelShowBadge: channel.showBadge,
    );
  }

  /// Cancels a notification through the backend that displayed it.
  /// Android tags apply only to Android notifications.
  Future<void> cancelNotification(int id, {String? tag}) async {
    _ensureInitialized();
    if (isWeb) {
      _webBackend.cancel(id);
    } else {
      await _flutterLocalNotificationsPlugin.cancel(id: id, tag: tag);
    }
  }

  /// Cancels notifications owned by the current backend.
  Future<void> cancelAllNotifications() async {
    _ensureInitialized();
    if (isWeb) {
      _webBackend.cancelAll();
    } else {
      await _flutterLocalNotificationsPlugin.cancelAll();
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (!_isInitialized ||
        response.notificationResponseType ==
            NotificationResponseType.notificationDismissed) {
      return;
    }
    if (response.notificationResponseType ==
        NotificationResponseType.selectedNotification) {
      _actionStreamController.add(NotificationClickAction(response.payload));
      return;
    }
    switch (response.actionId) {
      case NotificationConstants.markAsReadActionId:
        _actionStreamController.add(
          NotificationMarkReadAction(response.payload),
        );
      case NotificationConstants.replyActionId:
        _actionStreamController.add(
          NotificationReplyAction(
            payload: response.payload,
            replyText: response.input ?? '',
          ),
        );
      default:
        return;
    }
    // Android action buttons dismiss natively, even if no main isolate exists.
    // Foreground/custom actions also get best-effort cancellation here.
    final id = response.id;
    if (id != null) {
      unawaited(
        cancelNotification(id).catchError((Object _) {
          debugPrint('Unable to cancel notification after action');
        }),
      );
    }
  }

  /// Releases action ports and backend listeners. Existing stream subscriptions
  /// complete. Subscribe again when initializing a new lifecycle.
  void dispose() {
    _generation++;
    _isInitialized = false;
    _nativeSupport.dispose();
    if (PlatformUtils.currentPlatform == SupportedPlatform.windows) {
      _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            FlutterLocalNotificationsWindows
          >()
          ?.dispose();
    }
    _webBackend.dispose();
    final previousController = _actionStreamController;
    _actionStreamController =
        StreamController<BaseNotificationAction>.broadcast();
    unawaited(previousController.close());
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
  static Future<void> showNotification({required NotificationModel model}) =>
      instance.showNotification(model: model);

  /// Shows a chat-style notification
  static Future<void> showChatNotification({
    required ChatNotificationModel model,
  }) => instance.showChatNotification(model: model);

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

/// Forwards background actions to the running main isolate. When the app is
/// terminated, no main-isolate stream listener exists to receive these events.
@pragma('vm:entry-point')
Future<void> onDidReceiveBackgroundNotificationResponse(
  NotificationResponse response,
) async {
  if (response.notificationResponseType ==
      NotificationResponseType.selectedNotificationAction) {
    NativeNotificationSupport().sendBackgroundResponse(response);
  }
}
