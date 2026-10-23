import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:v_platform/v_platform.dart';

/// Native resources are never allocated by web consumers.
class NativeNotificationSupport {
  void startActionReceiver(void Function(NotificationResponse) onResponse) {}
  void sendBackgroundResponse(NotificationResponse response) {}
  Future<String?> loadImage(VPlatformFile? image) async => null;
  void dispose() {}
}
