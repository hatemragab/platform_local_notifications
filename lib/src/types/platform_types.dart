import 'package:flutter/foundation.dart';

/// Enum representing different platforms supported by the plugin
enum SupportedPlatform {
  android,
  ios,
  web,
  windows,
  macos,
  linux,
  unknown,
}

/// Extension to provide platform detection methods
extension PlatformDetection on SupportedPlatform {
  /// Returns true if the platform is mobile (Android or iOS)
  bool get isMobile =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Returns true if the platform is desktop (Windows, macOS, or Linux)
  bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Returns true if the platform supports chat notifications
  bool get supportsChatNotifications => isMobile;

  /// Returns true if the platform supports notification actions
  bool get supportsNotificationActions => isMobile;
}

/// Utility class for platform detection
class PlatformUtils {
  const PlatformUtils._();

  /// Detects the current platform
  static SupportedPlatform get currentPlatform {
    if (kIsWeb) return SupportedPlatform.web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return SupportedPlatform.android;
      case TargetPlatform.iOS:
        return SupportedPlatform.ios;
      case TargetPlatform.windows:
        return SupportedPlatform.windows;
      case TargetPlatform.macOS:
        return SupportedPlatform.macos;
      case TargetPlatform.linux:
        return SupportedPlatform.linux;
      default:
        return SupportedPlatform.unknown;
    }
  }

  /// Returns true if running on web
  static bool get isWeb => kIsWeb;

  /// Returns true if running on mobile platforms
  static bool get isMobile => currentPlatform.isMobile;

  /// Returns true if running on desktop platforms
  static bool get isDesktop => currentPlatform.isDesktop;

  /// Returns true if the current platform supports chat notifications
  static bool get supportsChatNotifications => currentPlatform.supportsChatNotifications;

  /// Returns true if the current platform supports notification actions
  static bool get supportsNotificationActions => currentPlatform.supportsNotificationActions;
}
