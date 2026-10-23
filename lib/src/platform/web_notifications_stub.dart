import '../models/notification_models.dart';

/// Browser operations are unavailable to native consumers.
class WebNotificationBackend {
  Future<bool> requestPermissions() async => false;
  Future<void> show(NotificationModel model, void Function() onClick) async {
    throw UnsupportedError('Browser notifications are unavailable');
  }

  void cancel(int id) {}
  void cancelAll() {}
  void dispose() {}
}
