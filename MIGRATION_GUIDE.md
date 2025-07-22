# Migration Guide: Version 1.x to 2.0

This guide will help you migrate your existing code from Platform Local Notifications version 1.x to version 2.0.

## Overview

Version 2.0 is a major rewrite that improves code quality, architecture, and developer experience. While there are breaking changes, the migration is straightforward and the new API is more intuitive.

## Breaking Changes

### 1. Class Renames

| Old Class                       | New Class                    |
| ------------------------------- | ---------------------------- |
| `ShowPluginNotificationModel`   | `NotificationModel`          |
| `PluginNotificationClickAction` | `NotificationClickAction`    |
| `PluginNotificationReplyAction` | `NotificationReplyAction`    |
| `PluginNotificationMarkRead`    | `NotificationMarkReadAction` |
| `NotifierData`                  | `NotificationData`           |

### 2. Method Changes

| Old Method                                    | New Method                                  |
| --------------------------------------------- | ------------------------------------------- |
| `PlatformNotifier.I.init()`                   | `PlatformNotifier.initialize()`             |
| `PlatformNotifier.I.showPluginNotification()` | `PlatformNotifier.showNotification()`       |
| `PlatformNotifier.I.showChatNotification()`   | `PlatformNotifier.showChatNotification()`   |
| `PlatformNotifier.I.requestPermissions()`     | `PlatformNotifier.requestPermissions()`     |
| `PlatformNotifier.I.cancel()`                 | `PlatformNotifier.cancelNotification()`     |
| `PlatformNotifier.I.cancelAll()`              | `PlatformNotifier.cancelAllNotifications()` |

### 3. Stream Changes

| Old Stream                                  | New Stream                      |
| ------------------------------------------- | ------------------------------- |
| `PlatformNotifier.I.platformNotifierStream` | `PlatformNotifier.actionStream` |

## Migration Steps

### Step 1: Update Dependencies

Update your `pubspec.yaml`:

```yaml
dependencies:
  platform_local_notifications: ^2.0.0
```

### Step 2: Update Imports

No changes needed - the main library export remains the same.

### Step 3: Update Initialization

**Before (v1.x):**

```dart
await PlatformNotifier.I.init(appName: "My App");
```

**After (v2.0):**

```dart
await PlatformNotifier.initialize(appName: "My App");
```

### Step 4: Update Notification Models

**Before (v1.x):**

```dart
final model = ShowPluginNotificationModel(
  id: 1,
  title: "Hello",
  body: "World",
  payload: "data",
);
```

**After (v2.0):**

```dart
final model = NotificationModel(
  id: 1,
  title: "Hello",
  body: "World",
  payload: "data",
);
```

### Step 5: Update Notification Display

**Before (v1.x):**

```dart
await PlatformNotifier.I.showPluginNotification(model, context);
```

**After (v2.0):**

```dart
await PlatformNotifier.showNotification(model: model, context: context);
```

### Step 6: Update Chat Notifications

**Before (v1.x):**

```dart
await PlatformNotifier.I.showChatNotification(
  model: model,
  userImage: "https://example.com/avatar.jpg",
  userName: "John Doe",
  conversationTitle: "Chat",
);
```

**After (v2.0):**

```dart
final chatModel = ChatNotificationModel(
  id: model.id,
  title: model.title,
  body: model.body,
  userImageUrl: "https://example.com/avatar.jpg",
  userName: "John Doe",
  conversationTitle: "Chat",
  payload: model.payload,
);

await PlatformNotifier.showChatNotification(model: chatModel);
```

### Step 7: Update Action Listeners

**Before (v1.x):**

```dart
PlatformNotifier.I.platformNotifierStream.listen((event) {
  if (event is PluginNotificationClickAction) {
    // Handle click
  }
  if (event is PluginNotificationReplyAction) {
    // Handle reply
  }
  if (event is PluginNotificationMarkRead) {
    // Handle mark as read
  }
});
```

**After (v2.0):**

```dart
PlatformNotifier.actionStream.listen((action) {
  switch (action.runtimeType) {
    case NotificationClickAction _:
      final clickAction = action as NotificationClickAction;
      // Handle click
      break;
    case NotificationReplyAction _:
      final replyAction = action as NotificationReplyAction;
      // Handle reply
      break;
    case NotificationMarkReadAction _:
      final markReadAction = action as NotificationMarkReadAction;
      // Handle mark as read
      break;
  }
});
```

### Step 8: Update Permission Requests

**Before (v1.x):**

```dart
final isGranted = await PlatformNotifier.I.requestPermissions();
```

**After (v2.0):**

```dart
final isGranted = await PlatformNotifier.requestPermissions();
```

### Step 9: Update Notification Cancellation

**Before (v1.x):**

```dart
await PlatformNotifier.I.cancel(123);
await PlatformNotifier.I.cancelAll();
```

**After (v2.0):**

```dart
await PlatformNotifier.cancelNotification(123);
await PlatformNotifier.cancelAllNotifications();
```

## New Features in 2.0

### 1. Model Validation

All notification models now have built-in validation:

```dart
final model = NotificationModel(
  id: 1,
  title: "Hello",
  body: "World",
);

if (model.isValid) {
  await PlatformNotifier.showNotification(model: model);
}
```

### 2. Better Error Handling

The new version provides specific error types:

```dart
try {
  await PlatformNotifier.showNotification(model: model);
} on StateError catch (e) {
  // Service not initialized
} on ArgumentError catch (e) {
  // Invalid model
} catch (e) {
  // Other errors
}
```

### 3. Platform Detection

New utilities for platform detection:

```dart
if (PlatformUtils.isMobile) {
  // Mobile-specific code
}

if (PlatformUtils.supportsChatNotifications) {
  // Chat notification code
}
```

### 4. Configuration Options

More flexible configuration:

```dart
final config = NotificationData(
  androidNotificationChannel: AndroidNotificationChannel(
    'custom_channel',
    'Custom Notifications',
    importance: Importance.high,
  ),
);

await PlatformNotifier.initialize(
  appName: 'My App',
  notificationData: config,
);
```

## Complete Migration Example

Here's a complete example showing the migration from v1.x to v2.0:

### Before (v1.x)

```dart
class MyNotificationService {
  Future<void> initialize() async {
    await PlatformNotifier.I.init(appName: "My App");
  }

  Future<void> showNotification() async {
    final model = ShowPluginNotificationModel(
      id: 1,
      title: "Hello",
      body: "World",
      payload: "data",
    );

    await PlatformNotifier.I.showPluginNotification(model, context);
  }

  void setupListeners() {
    PlatformNotifier.I.platformNotifierStream.listen((event) {
      if (event is PluginNotificationClickAction) {
        print('Clicked: ${event.payload}');
      }
    });
  }
}
```

### After (v2.0)

```dart
class MyNotificationService {
  Future<void> initialize() async {
    await PlatformNotifier.initialize(appName: "My App");
  }

  Future<void> showNotification() async {
    final model = NotificationModel(
      id: 1,
      title: "Hello",
      body: "World",
      payload: "data",
    );

    await PlatformNotifier.showNotification(model: model);
  }

  void setupListeners() {
    PlatformNotifier.actionStream.listen((action) {
      switch (action.runtimeType) {
        case NotificationClickAction _:
          final clickAction = action as NotificationClickAction;
          print('Clicked: ${clickAction.payload}');
          break;
      }
    });
  }
}
```

## Testing Your Migration

After migrating, test the following:

1. **Initialization**: Ensure the service initializes without errors
2. **Permissions**: Request and verify notification permissions
3. **Standard Notifications**: Show basic notifications
4. **Chat Notifications**: Test chat-style notifications (mobile only)
5. **Actions**: Verify click, reply, and mark-as-read actions work
6. **Cancellation**: Test notification cancellation

## Need Help?

If you encounter issues during migration:

1. Check the [README.md](README.md) for detailed documentation
2. Review the [example app](example/) for usage patterns
3. Check the [CHANGELOG.md](CHANGELOG.md) for detailed changes
4. Open an issue on GitHub with your specific problem

## Rollback Plan

If you need to rollback to v1.x:

1. Update `pubspec.yaml` to use version `^1.0.5`
2. Revert your code changes
3. Run `flutter pub get`

However, we recommend staying with v2.0 as it provides significant improvements in stability, performance, and developer experience.
