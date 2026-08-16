import 'package:flutter/foundation.dart';
import 'package:v_platform/v_platform.dart';

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
  bool get isMobile => VPlatforms.isMobile;

  /// Returns true if the platform is desktop (Windows, macOS, or Linux)
  bool get isDesktop => VPlatforms.isDesktop;

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

    if (VPlatforms.isAndroid) return SupportedPlatform.android;
    if (VPlatforms.isIOS) return SupportedPlatform.ios;
    if (VPlatforms.isWindows) return SupportedPlatform.windows;
    if (VPlatforms.isMacOs) return SupportedPlatform.macos;
    if (VPlatforms.isLinux) return SupportedPlatform.linux;

    return SupportedPlatform.unknown;
  }

  /// Returns true if running on web
  static bool get isWeb => VPlatforms.isWeb;

  /// Returns true if running on mobile platforms
  static bool get isMobile => currentPlatform.isMobile;

  /// Returns true if running on desktop platforms
  static bool get isDesktop => currentPlatform.isDesktop;

  /// Returns true if the current platform supports chat notifications
  static bool get supportsChatNotifications =>
      currentPlatform.supportsChatNotifications;

  /// Returns true if the current platform supports notification actions
  static bool get supportsNotificationActions =>
      currentPlatform.supportsNotificationActions;
}
