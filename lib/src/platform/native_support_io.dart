import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:v_platform/v_platform.dart';

import '../constants/notification_constants.dart';

/// Owns resources that are unavailable in a browser.
class NativeNotificationSupport {
  ReceivePort? _receivePort;

  void startActionReceiver(void Function(NotificationResponse) onResponse) {
    final port = ReceivePort();
    if (!IsolateNameServer.registerPortWithName(
      port.sendPort,
      NotificationConstants.actionReceiverPortName,
    )) {
      port.close();
      throw StateError('A notification action receiver is already registered');
    }
    _receivePort = port;
    port.listen((dynamic data) {
      if (data is! Map ||
          data['actionId'] is! String ||
          (data['payload'] != null && data['payload'] is! String) ||
          (data['notificationId'] != null && data['notificationId'] is! int) ||
          (data['replyText'] != null && data['replyText'] is! String)) {
        return;
      }
      onResponse(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          id: data['notificationId'] as int?,
          actionId: data['actionId'] as String,
          payload: data['payload'] as String?,
          input: data['replyText'] as String?,
        ),
      );
    });
  }

  void sendBackgroundResponse(NotificationResponse response) {
    IsolateNameServer.lookupPortByName(
      NotificationConstants.actionReceiverPortName,
    )?.send(<String, Object?>{
      'actionId': response.actionId,
      'payload': response.payload,
      'notificationId': response.id,
      'replyText': response.input,
    });
  }

  Future<String?> loadImage(VPlatformFile? image) async {
    if (image == null) return null;
    try {
      final localPath = image.fileLocalPath;
      if (localPath != null) {
        return await File(localPath).exists() ? localPath : null;
      }
      final url = image.fullNetworkUrl;
      if (url == null) return null;
      final file = await DefaultCacheManager()
          .getSingleFile(url, key: image.getCachedUrlKey)
          .timeout(const Duration(seconds: 10));
      return file.path;
    } catch (_) {
      // An unavailable avatar must not prevent message delivery.
      debugPrint('Notification avatar unavailable; using text only');
      return null;
    }
  }

  void dispose() {
    if (_receivePort != null) {
      IsolateNameServer.removePortNameMapping(
        NotificationConstants.actionReceiverPortName,
      );
      _receivePort!.close();
      _receivePort = null;
    }
  }
}
