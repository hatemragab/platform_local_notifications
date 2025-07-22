# Platform Local Notifications

A comprehensive cross-platform local notifications plugin for Flutter supporting Android, iOS, Web, Windows, macOS, and Linux with chat-style notifications and interactive actions.

## Features

- 🌍 **Cross-Platform Support**: Works on all major Flutter platforms
- 💬 **Chat Notifications**: Interactive notifications with reply functionality
- 🔔 **Standard Notifications**: Simple, customizable notifications
- 🎯 **Action Handling**: Handle notification clicks, replies, and mark-as-read actions
- 🔐 **Permission Management**: Automatic permission requests for each platform
- 🖼️ **Image Caching**: Automatic caching of user profile images
- 📱 **Platform Optimization**: Platform-specific optimizations and features

## Supported Platforms

| Platform | Standard Notifications | Chat Notifications | Actions |
| -------- | ---------------------- | ------------------ | ------- |
| Android  | ✅                     | ✅                 | ✅      |
| iOS      | ✅                     | ✅                 | ✅      |
| Web      | ✅                     | ⚠️ (Limited)       | ❌      |
| Windows  | ✅                     | ❌                 | ❌      |
| macOS    | ✅                     | ❌                 | ❌      |
| Linux    | ✅                     | ❌                 | ❌      |

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  platform_local_notifications: ^2.0.0
```

## Quick Start

### 1. Initialize the Service

```dart
import 'package:platform_local_notifications/platform_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PlatformNotifier.initialize(appName: 'My App');

  runApp(MyApp());
}
```

### 2. Request Permissions

```dart
Future<void> requestNotificationPermissions() async {
  final isGranted = await PlatformNotifier.requestPermissions();

  if (isGranted == true) {
    print('Notification permissions granted');
  } else {
    print('Notification permissions denied');
  }
}
```

### 3. Show a Standard Notification

```dart
Future<void> showSimpleNotification() async {
  final notificationModel = NotificationModel(
    id: DateTime.now().millisecondsSinceEpoch,
    title: 'Hello!',
    body: 'This is a simple notification',
    payload: 'notification_data',
  );

  await PlatformNotifier.showNotification(model: notificationModel);
}
```

### 4. Show a Chat Notification

```dart
Future<void> showChatNotification() async {
  final chatModel = ChatNotificationModel(
    id: DateTime.now().millisecondsSinceEpoch,
    title: 'New Message',
    body: 'Hello! How are you?',
    userImageUrl: 'https://example.com/avatar.jpg',
    userName: 'John Doe',
    conversationTitle: 'Group Chat',
    payload: 'chat_data',
  );

  await PlatformNotifier.showChatNotification(model: chatModel);
}
```

### 5. Handle Notification Actions

```dart
void setupNotificationListeners() {
  PlatformNotifier.actionStream.listen((action) {
    switch (action.runtimeType) {
      case NotificationClickAction _:
        final clickAction = action as NotificationClickAction;
        print('Notification clicked: ${clickAction.payload}');
        break;

      case NotificationReplyAction _:
        final replyAction = action as NotificationReplyAction;
        print('User replied: ${replyAction.replyText}');
        print('Payload: ${replyAction.payload}');
        break;

      case NotificationMarkReadAction _:
        final markReadAction = action as NotificationMarkReadAction;
        print('Notification marked as read: ${markReadAction.payload}');
        break;
    }
  });
}
```

### 6. Check App Launch Details

```dart
Future<void> checkAppLaunchDetails() async {
  final launchDetails = await PlatformNotifier.appLaunchNotification;

  if (launchDetails != null) {
    print('App was launched from notification!');
    print('Did notification launch app: ${launchDetails.didNotificationLaunchApp}');
    print('Payload: ${launchDetails.notificationResponse?.payload}');
    print('Action ID: ${launchDetails.notificationResponse?.actionId}');
    print('Input: ${launchDetails.notificationResponse?.input}');
  } else {
    print('App was not launched from a notification');
  }
}
```

## Advanced Usage

### Custom Configuration

```dart
final customConfig = NotificationData(
  androidNotificationChannel: AndroidNotificationChannel(
    'custom_channel',
    'Custom Notifications',
    importance: Importance.high,
  ),
  initializationSettingsAndroid: AndroidInitializationSettings('@mipmap/ic_launcher'),
  initializationSettingsDarwin: DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  ),
);

await PlatformNotifier.initialize(
  appName: 'My App',
  notificationData: customConfig,
);
```

### Custom Notification Details

```dart
final notificationModel = NotificationModel(
  id: 1,
  title: 'Custom Notification',
  body: 'With custom styling',
  payload: 'custom_data',
  androidDetails: AndroidNotificationDetails(
    'custom_channel',
    'Custom Channel',
    channelDescription: 'Custom notification channel',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    playSound: true,
  ),
  iosDetails: DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    badgeNumber: 1,
  ),
  macOsDetails: DarwinNotificationDetails(
    presentSound: true,
    subtitle: 'Custom Subtitle',
    presentBadge: true,
  ),
);

await PlatformNotifier.showNotification(model: notificationModel);
```

### Custom Chat Notification

```dart
final chatModel = ChatNotificationModel(
  id: 1,
  title: 'New Message',
  body: 'Hello from John!',
  userImageUrl: 'https://example.com/john.jpg',
  userName: 'John Doe',
  conversationTitle: 'Team Chat',
  markAsReadLabel: 'Mark as Read',
  replyLabel: 'Quick Reply',
  replyHint: 'Type your reply...',
  messages: [
    Message(
      'Hello from John!',
      DateTime.now().subtract(Duration(minutes: 5)),
      Person(name: 'John Doe'),
    ),
    Message(
      'How are you doing?',
      DateTime.now(),
      Person(name: 'John Doe'),
    ),
  ],
  payload: 'chat_123',
);

await PlatformNotifier.showChatNotification(model: chatModel);
```

### Cancel Notifications

```dart
// Cancel a specific notification
await PlatformNotifier.cancelNotification(123);

// Cancel a notification with tag
await PlatformNotifier.cancelNotification(123, tag: 'chat_notification');

// Cancel all notifications
await PlatformNotifier.cancelAllNotifications();
```

## Platform-Specific Features

### Android

- Custom notification channels
- Messaging style notifications
- Action buttons (Reply, Mark as Read)
- Rich notifications with images
- Priority and importance settings

### iOS

- Badge numbers
- Sound and alert settings
- Critical notifications support
- Custom notification categories

### Web

- Browser notifications
- Permission handling
- Limited chat functionality

### Desktop (Windows/macOS/Linux)

- Native desktop notifications
- System integration
- Custom notification sounds

## Error Handling

The plugin includes comprehensive error handling:

```dart
try {
  await PlatformNotifier.showNotification(model: notificationModel);
} on StateError catch (e) {
  print('Service not initialized: $e');
} on ArgumentError catch (e) {
  print('Invalid notification model: $e');
} catch (e) {
  print('Unexpected error: $e');
}
```

## Best Practices

### 1. Initialize Early

Always initialize the service in your app's startup:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PlatformNotifier.initialize(appName: 'My App');

  runApp(MyApp());
}
```

### 2. Handle Permissions

Request permissions early and handle denied cases:

```dart
Future<void> setupNotifications() async {
  final isGranted = await PlatformNotifier.requestPermissions();

  if (isGranted != true) {
    // Show dialog explaining why notifications are needed
    showPermissionDialog();
  }
}
```

### 3. Use Unique IDs

Always use unique IDs for notifications to avoid conflicts:

```dart
final notificationId = DateTime.now().millisecondsSinceEpoch;
// or
final notificationId = Random().nextInt(1000000);
```

### 4. Validate Models

The plugin automatically validates notification models, but you can also validate manually:

```dart
final model = NotificationModel(
  id: 1,
  title: 'Test',
  body: 'Test body',
);

if (model.isValid) {
  await PlatformNotifier.showNotification(model: model);
}
```

### 5. Dispose Properly

Dispose the service when your app is terminated:

```dart
@override
void dispose() {
  PlatformNotifier.dispose();
  super.dispose();
}
```

## Troubleshooting

### Common Issues

1. **Notifications not showing on Android**

   - Ensure notification channel is created
   - Check notification permissions
   - Verify app is not in battery optimization

2. **Chat notifications not working**

   - Only supported on mobile platforms (Android/iOS)
   - Ensure proper image URL format
   - Check network connectivity for image loading

3. **Actions not working**

   - Ensure proper isolate communication setup
   - Check action IDs match constants
   - Verify background notification handling

4. **Web notifications not working**
   - Ensure HTTPS in production
   - Check browser notification permissions
   - Verify user interaction before showing notifications

### Debug Mode

Enable debug logging:

```dart
// The plugin automatically logs debug information
// Check console output for initialization and error messages
```

## API Reference

### Classes

- `PlatformNotifier` - Main entry point for notification operations
- `PlatformNotificationService` - Core service implementation
- `NotificationModel` - Standard notification configuration
- `ChatNotificationModel` - Chat-style notification configuration
- `NotificationData` - Plugin configuration data
- `BaseNotificationAction` - Base class for notification actions
- `NotificationClickAction` - Click action event
- `NotificationReplyAction` - Reply action event
- `NotificationMarkReadAction` - Mark as read action event

### Methods

#### PlatformNotifier

- `initialize(appName, notificationData)` - Initialize the service
- `requestPermissions()` - Request notification permissions
- `showNotification(model, context)` - Show standard notification
- `showChatNotification(model, context)` - Show chat notification
- `cancelNotification(id, tag)` - Cancel specific notification
- `cancelAllNotifications()` - Cancel all notifications
- `appLaunchNotification` - Get app launch details from notification
- `dispose()` - Dispose the service

#### NotificationModel

- `copyWith(...)` - Create a copy with modified fields
- `isValid` - Check if the model is valid

#### ChatNotificationModel

- `copyWith(...)` - Create a copy with modified fields
- `isValid` - Check if the model is valid

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

### 2.0.0

- Complete code refactoring and reorganization
- Improved error handling and validation
- Better documentation and examples
- Enhanced type safety
- Cleaner API design
- Platform-specific optimizations

### 1.0.5

- Initial release with basic functionality
