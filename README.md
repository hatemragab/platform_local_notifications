# Platform Local Notifications

A Flutter facade for local notifications on Android, iOS, macOS, Linux,
Windows, and web. Android includes messaging-style notifications with reply
and mark-as-read actions. Other platforms display chat models as standard
notifications.

## Installation

```yaml
dependencies:
  platform_local_notifications: ^4.0.0
  # Only needed when constructing chat avatars:
  v_platform: ^3.0.0
```

Version 4.0 requires Dart 3.13 and Flutter 3.47 or newer.
It uses `flutter_local_notifications: ^22.3.3`, `flutter_cache_manager: ^3.5.0`,
and `web: ^1.1.2`. All direct package and example dependencies use their latest
stable versions. Flutter itself pins `material_color_utilities` and `test_api`;
these are kept at the SDK-compatible versions without dependency overrides.

The package re-exports the native notification plugin. Calls made directly to
that plugin now use named parameters; the `PlatformNotifier` facade remains
unchanged. See [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md).

## Standalone Material and Cupertino

The package itself uses Flutter foundation and native notification types without
requiring Material or Cupertino widgets. Consumers can use either of Flutter's
standalone design libraries. The example uses `material_ui: ^1.8.0`, and its
regression suite also exercises the notification facade under
`cupertino_ui: ^1.1.4`. No legacy `package:material_ui/material_ui.dart` or
`package:cupertino_ui/cupertino_ui.dart` imports remain in maintained package/example code.
A compatibility bridge is only needed if your own widget subtree contains
unmigrated third-party widgets; the notification service does not need one.

## Platform capabilities

| Platform | Standard notifications | Built-in chat actions | Backend |
| --- | --- | --- | --- |
| Android | Yes | Reply, mark as read | flutter_local_notifications |
| iOS | Yes | No; standard fallback | flutter_local_notifications |
| macOS | Yes | No; standard fallback | flutter_local_notifications |
| Linux | Yes | No; standard fallback | flutter_local_notifications |
| Windows | Yes | No; standard fallback | flutter_local_notifications |
| Web | Supported desktop browsers | No; standard fallback | Browser Notifications API |

Click events include the model's payload. OS settings can still suppress
notifications even when a permission request succeeds. Linux and Windows
have no application runtime permission prompt, so `requestPermissions()`
returns `true` there; this does not verify system notification settings.

Web notifications require HTTPS or localhost and permission requested from a
user gesture. This package uses page-scoped notifications: keep the page
open to receive clicks. Mobile browsers that require service-worker
notifications, including iOS browsers, are not supported by this backend.
Both JavaScript and WebAssembly compilation are supported; compilation does
not establish browser permission or delivery support.

## Setup

### Android

Use Android API 24 or newer, compile SDK 36, Java 17, AGP 8.11.1 or newer,
and core library desugaring as required by
[flutter_local_notifications 22.3.2](https://pub.dev/packages/flutter_local_notifications/versions/22.3.2).
The example uses Gradle 9.3.1, AGP 9.1.0, and built-in Kotlin with Java 17.

Add this receiver inside your manifest's `<application>` for chat actions:

```xml
<receiver
    android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver"
    android:exported="false" />
```

Network avatars also require `android.permission.INTERNET` in the main
manifest. Provide an Android notification icon resource suitable for your
app; the default is `@mipmap/ic_launcher`.

### iOS and macOS

For foreground notification presentation, set the notification center's
delegate in your app delegate, as shown in the example's iOS runner:

```swift
UNUserNotificationCenter.current().delegate = self
```

The example adopts UIScene and Swift Package Manager on Apple platforms.

For additional native setup, custom categories, or background handlers,
follow the underlying plugin's platform instructions. Built-in chat action
buttons are Android-only. Critical-alert permission is not requested by the
facade; applications with the required entitlement can use the exported
platform plugin directly.

### Linux and Windows

Linux requires a running desktop notification server. Windows uses the native
notification plugin with an application name, app user model ID, and GUID.
Defaults derive a stable identity from `appName`; production applications should
provide `NotificationData.initializationSettingsWindows` explicitly to keep
identity stable across application renames. The legacy `local_notifier`
dependency is removed, including its deprecated macOS notification APIs.
See the [example](example/) for native runner configuration.

## Usage

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:platform_local_notifications/platform_local_notifications.dart';
import 'package:v_platform/v_platform.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlatformNotifier.initialize(appName: 'My App');
  // runApp(...);
}

Future<bool?> requestFromButton() => PlatformNotifier.requestPermissions();

Future<void> showMessage() async {
  await PlatformNotifier.showChatNotification(
    model: ChatNotificationModel(
      id: 42,
      title: 'New message',
      body: 'Hello!',
      userName: 'Alex',
      userImageUrl: VPlatformFile.fromUrl(
        networkUrl: 'https://example.com/avatar.jpg',
      ),
      payload: 'conversation-42',
    ),
  );
}

Future<void> showStandard() => PlatformNotifier.showNotification(
  model: const NotificationModel(
    id: 43,
    title: 'Reminder',
    body: 'Your meeting starts soon.',
    payload: 'meeting-43',
  ),
);

StreamSubscription<BaseNotificationAction> listenToActions() {
  return PlatformNotifier.actionStream.listen((action) {
    switch (action) {
      case NotificationClickAction():
        // Navigate using action.payload.
        break;
      case NotificationReplyAction():
        // Send action.replyText to the conversation in action.payload.
        break;
      case NotificationMarkReadAction():
        // Mark the conversation in action.payload as read.
        break;
    }
  });
}
```

Notification IDs must fit a signed 32-bit integer (`-2147483648` through
`2147483647`). Reusing an ID replaces the notification on supporting
platforms. Do not use epoch milliseconds directly: those exceed the native
ID range. Empty titles and bodies remain allowed for custom native layouts.
`model.isValid` checks the identifier before delivery.

Avatars are optional (`userImageUrl: null`), loaded only for Android chat,
and cached for network images. Missing files and failed or slow downloads
fall back to text without blocking notification delivery indefinitely.

## Configuration

```dart
const data = NotificationData(
  androidNotificationChannel: AndroidNotificationChannel(
    'messages',
    'Messages',
    description: 'Incoming messages',
    importance: Importance.high,
  ),
  initializationSettingsDarwin: DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  ),
  initializationSettingsLinux: LinuxInitializationSettings(
    defaultActionName: 'Open',
  ),
);

// During application startup:
// await PlatformNotifier.initialize(appName: 'My App', notificationData: data);
```

`NotificationData` controls initialization. The older
`NotificationConfiguration` value type remains available for compatibility;
it is not accepted by `initialize`. The configured Android channel is used
for both standard and chat defaults. Individual models can provide
platform-specific notification details. Android chat generates its own
messaging style and action buttons, retaining channel, icon, sound,
vibration, tag, grouping, priority, importance, and color overrides.
Android channel settings are persisted by the OS; changing a channel's
importance or sound after creation requires a new channel ID or user action
in system settings.

Concurrent initialization calls share one operation. Once initialized,
subsequent calls retain the first configuration. A failed initialization can
be retried. Configure Apple permission prompts explicitly if you want to
request permission later from a button.

## Cancellation, launch, and lifecycle

```dart
Future<void> cancelMessage() => PlatformNotifier.cancelNotification(42);
Future<void> cancelEverything() => PlatformNotifier.cancelAllNotifications();

Future<bool> wasOpenedFromNotification() async {
  final details = await PlatformNotifier.appLaunchNotification;
  return details?.didNotificationLaunchApp == true;
}
```

Android tags can be passed to `cancelNotification(id, tag: ...)`.
Web cancellation applies to notifications tracked during the current initialized
session. All native platforms use the delivery plugin for cancellation and
launch details. Web returns `null` for launch details;
Linux launch support depends on the notification server and runner setup.

Android chat actions dismiss the notification natively, including when the
main isolate is absent. Background actions are forwarded to `actionStream`
only while the main isolate and its receiver exist. The facade does not
persist or replay actions after app termination; applications needing that
behavior should configure their own durable background handling.

Cancel your `StreamSubscription` when its owner is disposed. Call
`PlatformNotifier.dispose()` when the application no longer needs the
service, rather than whenever an individual screen closes. Disposal
releases ports and backend listeners without dismissing existing
notifications. The singleton can be initialized again; disposal completes existing action
subscriptions, and a new action stream is available for the next lifecycle. If initialization is still pending, await it before
starting a new initialization after disposal.

Operations before initialization throw `StateError`; invalid model IDs throw
`ArgumentError`. Backend and permission errors propagate to the caller.
Notification payloads and reply text are not written to service debug logs.

## Development

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test example/lib example/test
flutter analyze
flutter test --coverage
cd example
flutter pub get
flutter test
flutter build web
flutter build web --wasm
flutter build apk --debug
```

For web development, run `flutter run -d web-server --web-port 8765` in
`example/`, then open the localhost URL in a desktop browser.

Unit tests use mocked platform channels; builds and unit tests do not prove
native permission prompts, delivery, or action behavior. Validate those on
the affected OS before shipping. See [CHANGELOG.md](CHANGELOG.md),
[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md), and [LICENSE](LICENSE).
