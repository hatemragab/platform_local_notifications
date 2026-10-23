import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import '../models/notification_models.dart';

/// Page-scoped browser notifications with stable IDs and click payloads.
class WebNotificationBackend {
  final Map<int, web.Notification> _notifications = {};

  bool get _isSupported =>
      web.window.has('Notification') && web.window.isSecureContext;

  Future<bool> requestPermissions() async {
    if (!_isSupported) return false;
    return (await web.Notification.requestPermission().toDart).toDart ==
        'granted';
  }

  Future<void> show(NotificationModel model, void Function() onClick) async {
    if (!_isSupported) {
      throw UnsupportedError(
        'Notifications require a supported browser and HTTPS or localhost',
      );
    }
    if (web.Notification.permission != 'granted') {
      throw StateError('Notification permission has not been granted');
    }
    final notification = web.Notification(
      model.title,
      web.NotificationOptions(body: model.body, tag: model.id.toString()),
    );
    cancel(model.id);
    _notifications[model.id] = notification;
    notification.onclick = ((web.Event _) => onClick()).toJS;
    notification.onclose = ((web.Event _) {
      if (_notifications[model.id] == notification) {
        _notifications.remove(model.id);
      }
      notification.onclick = null;
      notification.onclose = null;
    }).toJS;
  }

  void cancel(int id) {
    final notification = _notifications.remove(id);
    if (notification == null) return;
    notification.onclick = null;
    notification.onclose = null;
    notification.close();
  }

  void cancelAll() {
    for (final id in _notifications.keys.toList()) {
      cancel(id);
    }
  }

  void dispose() {
    // Releasing listeners does not dismiss notifications already shown.
    for (final notification in _notifications.values) {
      notification.onclick = null;
      notification.onclose = null;
    }
    _notifications.clear();
  }
}
