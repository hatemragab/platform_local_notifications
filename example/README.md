# Notification demo

Requires Dart 3.13 and Flutter 3.47 or newer. The UI uses the standalone
`material_ui` package; widget tests also verify a `cupertino_ui` consumer.
Apple runners use Swift Package Manager and UIScene; Android uses AGP 9
built-in Kotlin.

Demonstrates initialization, permission requests, standard/custom/chat
notifications, cancellation, launch details, and action stream events.
Android chat actions fall back to standard notifications on other platforms.

```sh
flutter pub get
flutter test
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8765
flutter build web
flutter build web --wasm
flutter build apk --debug
```

Press **Request Permissions** before showing notifications. On web, use a
supported desktop browser over HTTPS or localhost; page notifications do
not work on mobile browsers requiring service workers. Windows and Linux
have no runtime permission prompt. Native delivery must be checked manually
on each target OS; widget tests and builds do not establish delivery proof.

The demo owns its stream subscription. Its screen does not dispose the
application-wide notification singleton. See the [package README](../README.md)
for setup, lifecycle, platform limitations, and API examples.

For a real web notification click check, allow the localhost origin in Chrome
and allow both Chrome notification entries in macOS System Settings. Show a
notification, note its payload in **Last Action**, click the actual OS
notification, and verify **Notification clicked** contains that same payload.
A passing API call alone does not prove OS notification delivery. Focus and
screen-sharing notification settings may suppress banners.
