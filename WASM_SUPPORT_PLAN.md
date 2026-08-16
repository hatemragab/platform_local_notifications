# Issue #5: WebAssembly Support Plan

**Prepared:** 2026-08-16
**Issue:** [WebAssembly (WASM) support roadmap?](https://github.com/hatemragab/platform_local_notifications/issues/5)
**Related work:** [PR #6 — `feat: adds support for WASM`](https://github.com/hatemragab/platform_local_notifications/pull/6)

## Decision

WASM support is achievable, but PR #6 should not be merged as-is. The recommended implementation is a 3.0 modernization that upgrades to `flutter_local_notifications` 22.3.0, uses its maintained web backend, and removes the two dependencies that currently introduce legacy web libraries. This produces one notification backend for display, cancellation, IDs, payloads, launch handling, and actions instead of maintaining a separate custom web implementation.

## What Currently Blocks WASM

`flutter build web --wasm` fails through two dependency paths:

```text
platform_local_notifications
├── quick_notify_2 ───────────────► dart:html
└── v_platform ─► universal_html ─► dart:html
```

The package also imports `dart:io` directly from its shared service and `v_platform` sources import both `dart:io` and `universal_html` from common libraries. Flutter's [WASM guidance](https://docs.flutter.dev/platform-integration/web/wasm) requires `package:web` and static `dart:js_interop`; `dart:html`, `dart:js`, and `package:js` are incompatible.

The current web path has functional gaps beyond compilation:

- `quick_notify_2` receives only title/body, so the notification ID and payload are lost.
- `cancelNotification()` always calls `flutter_local_notifications`, not the web backend that displayed the notification.
- Web permission and display errors are swallowed or logged rather than represented in the public contract.
- The web display method is not awaited.

## Assessment of PR #6

The PR correctly identifies legacy web imports and replaces some `dart:io` platform checks. It is not a safe production patch because it:

- depends on an unpinned Git `main` branch of `raphaexa/quick_notify_2`;
- changes the public `VPlatformFile` field to a new `PlatformFile` without a migration path;
- changes generated `.flutter-plugins-dependencies` containing contributor-specific `/Users/...` paths;
- changes one test file only for the model rename/formatting, with no permission, display, cancellation, payload, action, or WASM behavior tests;
- includes broad formatting noise unrelated to the feature.

The fork itself currently declares Dart `>=2.15.1 <3.0.0` while importing `dart:js_interop`, evaluates generated JavaScript through `eval`, and reads notification permission immediately instead of awaiting the browser permission promise. `eval` is also incompatible with strict Content Security Policy. These problems make the fork unsuitable as a published stable dependency.

## Proven Upstream Path

[`flutter_local_notifications` 22.3.0](https://github.com/MaikuB/flutter_local_notifications/releases/tag/flutter_local_notifications-v22.3.0) includes an official web implementation. Its web package uses `package:web` and `dart:js_interop`, provides service-worker delivery, tag-based IDs, cancellation, payload/launch details, and browser actions. Version 22 added web support; version 21 established these minimums:

- Flutter 3.38.1 and Dart 3.10
- Android API 24, iOS 13, and macOS 10.15
- Android compile SDK 36 and AGP 8.11.1
- Java 17 for the Android toolchain

An isolated probe on this repository's Flutter 3.44.1/Dart 3.12.1 toolchain verified the proposed dependency:

| Probe | Result |
|---|---|
| `flutter pub get` with `flutter_local_notifications: ^22.3.0` | Passed |
| WASM build without direct `flutter_web_plugins` dependency | Failed: generated web registrant could not resolve the SDK package |
| Add `flutter_web_plugins: {sdk: flutter}` and rebuild | Passed: `flutter build web --wasm` produced `build/web` |
| Include `flutter_cache_manager: ^3.4.2` in the probe | WASM build still passed |

The explicit `flutter_web_plugins` dependency should therefore remain as a documented workaround until upstream supplies or no longer requires it on the supported Flutter toolchain.

## Target Dependency Set

```yaml
environment:
  sdk: ^3.10.0
  flutter: ">=3.38.1"

dependencies:
  flutter:
    sdk: flutter
  flutter_web_plugins:
    sdk: flutter
  flutter_local_notifications: ^22.3.0
  flutter_cache_manager: ^3.4.2
```

Remove `quick_notify_2` and `local_notifier`. Prefer removing `v_platform` from this package as well. If retaining `VPlatformFile` is mandatory, `v_platform` must first receive and publish its own verified WASM-safe release using conditional IO helpers and `package:web`; merely raising its version constraint will not solve the current imports.

## Implementation Design

### 1. Make Models Platform-Neutral

Replace `VPlatformFile` in the next major API with a small package-owned value type that does not expose `dart:io`:

```dart
sealed class NotificationImageSource {
  const NotificationImageSource();
}

final class NetworkNotificationImage extends NotificationImageSource {
  const NetworkNotificationImage(this.uri);
  final Uri uri;
}

final class FilePathNotificationImage extends NotificationImageSource {
  const FilePathNotificationImage(this.path);
  final String path;
}
```

Bytes and asset variants can be added if they are required by real callers. Validate unsupported source/platform combinations rather than importing `File` into shared code. Network images map directly to `WebNotificationDetails.iconUrl` or `imageUrl`; native file resolution belongs in an IO-only helper selected with conditional imports.

### 2. Use Flutter Platform Primitives

In `lib/src/types/platform_types.dart`, replace `VPlatforms` with `kIsWeb` and `defaultTargetPlatform`. Remove `dart:io` platform checks from the shared service. Any real filesystem operation should live behind files such as:

```text
lib/src/io/image_resolver.dart
lib/src/io/image_resolver_io.dart
lib/src/io/image_resolver_stub.dart
```

The shared library must never import the IO implementation directly.

### 3. Initialize One Backend

`PlatformNotificationService.initialize()` should create a complete `InitializationSettings` value for every advertised target, including `WebInitializationSettings`, and call the upstream plugin once. The lifecycle must remain idempotent and await concurrent initialization rather than racing.

For web permission requests:

```dart
final webPlugin = plugin.resolvePlatformSpecificImplementation<
    WebFlutterLocalNotificationsPlugin>();
return await webPlugin?.requestNotificationsPermission() ?? false;
```

Permission requests must remain callable from a user gesture; initialization must not prompt automatically.

### 4. Unify Display and Cancellation

Delete `_showWebNotification()` and route all supported platforms through `FlutterLocalNotificationsPlugin.show()`:

```dart
final details = NotificationDetails(
  web: WebNotificationDetails(
    iconUrl: model.iconUrl,
    imageUrl: model.imageUrl,
    requireInteraction: model.requireInteraction,
  ),
  // Existing native details are mapped here as well.
);

await plugin.show(
  id: model.id,
  title: model.title,
  body: model.body,
  notificationDetails: details,
  payload: model.payload,
);
```

Cancellation then becomes one coherent call:

```dart
await plugin.cancel(id: id, tag: tag);
```

This preserves web IDs through the browser notification `tag`, enables replacement by ID, and allows the upstream web adapter to close the correct notification.

### 5. Complete Response Handling

Map `NotificationResponseType.selectedNotification`, `selectedNotificationAction`, and `notificationDismissed`. Preserve payloads and action IDs in the existing typed action stream. Do not log reply text or payload contents. Document that action buttons are supported by Chrome/Edge but ignored by Firefox/Safari, as stated in the [upstream web documentation](https://github.com/MaikuB/flutter_local_notifications/tree/flutter_local_notifications-v22.3.0/flutter_local_notifications_web).

### 6. Document Web Limitations

The browser requires HTTPS or localhost, permission must be requested from a user action, and an active service worker is required. Scheduled and repeating web notifications are not supported by the upstream plugin and throw `UnsupportedError`. Flutter/WASM also requires a WasmGC-capable browser; current Flutter documentation notes limitations on Safari, Firefox, and every iOS browser. The package should expose these limitations rather than claiming identical features everywhere.

## File-by-File Change Map

| File/area | Planned change |
|---|---|
| `pubspec.yaml` | Raise SDK floors, upgrade FNL, add temporary SDK dependency, remove three redundant/blocking packages |
| `lib/platform_local_notifications.dart` | Stop wildcard-exporting the entire upstream package or explicitly treat the change as part of 3.0 |
| `lib/src/types/platform_types.dart` | Use Flutter platform primitives only |
| `lib/src/models/notification_models.dart` | Add web details/image fields and migrate from `VPlatformFile` |
| `lib/src/services/platform_notification_service.dart` | One initialized backend for permissions, display, cancel, launch, and responses |
| `lib/src/io/*` | Conditional native image resolution with a web-safe stub |
| `test/` | Mockable backend tests for every operation and response type |
| `example/` | Real permission button, show/replace/cancel controls, payload/action output, and non-template test |
| `.github/workflows/` | Analyze, test, coverage, JavaScript build, WASM build, native build matrix, publish dry run |

## Acceptance Matrix

The feature is complete only when all of the following pass:

1. `dart format --output=none --set-exit-if-changed ...`
2. `flutter analyze`
3. Unit tests prove initialize, permission, show, same-ID replacement, cancel, payload, launch, selected action, dismissal, denial, and unsupported features.
4. `flutter build web` completes with no WASM dry-run warning.
5. `flutter build web --wasm` completes in CI from a clean clone.
6. Chrome/Edge tests on localhost or HTTPS prove grant/deny, visible delivery, replacement, cancellation, click payload, action callback, closed-app launch, and service-worker update behavior.
7. JavaScript fallback behavior is verified for browsers that cannot run Flutter/WASM.
8. Android, iOS, macOS, Linux, and Windows regression builds pass after the backend consolidation.
9. `flutter pub publish --dry-run` has no prerelease dependency or generated-file warning.

## Delivery Sequence and Estimate

1. **Baseline and test seam (0.5–1 day):** make the service injectable, repair the example test, and capture existing behavior.
2. **Dependency/API migration (1–2 days):** upgrade FNL, change named arguments and response enums, introduce the image type, and remove old backends.
3. **Web/WASM behavior (1 day):** initialize the service worker, add web details, permission, ID/payload/cancel behavior, and browser-facing errors.
4. **CI and browser/native verification (1–2 days):** add build gates, run browser scenarios, and regress native platforms.

Expected effort is roughly 3.5–6 focused engineering days, plus access to Windows/Linux runners and representative browsers/devices. This should be delivered as version 3.0 because the current package re-exports upstream APIs, FNL 22 raises platform floors, and replacing `VPlatformFile` changes the public model contract.

## Suggested Issue Update

The following response is ready to post after implementation work begins; it has **not** been posted:

> WASM support is now planned for the 3.0 modernization. We confirmed the current blockers are legacy `dart:html` imports from `quick_notify_2` and `v_platform`, and verified that the maintained `flutter_local_notifications` 22 web backend can compile with `flutter build web --wasm`. The implementation will consolidate web/native behavior, preserve IDs and payloads, add cancellation and browser tests, and document browser limitations. PR #6 will be used as research, but its Git dependency and public API break will be replaced with a tested, published-dependency solution.
