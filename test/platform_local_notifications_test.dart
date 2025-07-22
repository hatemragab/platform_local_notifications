import 'package:flutter_test/flutter_test.dart';
import 'package:platform_local_notifications/platform_local_notifications.dart';

void main() {
  group('Platform Local Notifications Tests', () {
    test('NotificationModel creation', () {
      // Valid model
      final validModel = NotificationModel(
        id: 1,
        title: 'Test Title',
        body: 'Test Body',
        payload: 'test_payload',
      );
      expect(validModel.id, 1);
      expect(validModel.title, 'Test Title');
      expect(validModel.body, 'Test Body');
      expect(validModel.payload, 'test_payload');

      // Model with empty title (should still be created)
      final modelWithEmptyTitle = NotificationModel(
        id: 1,
        title: '',
        body: 'Test Body',
      );
      expect(modelWithEmptyTitle.title, '');
      expect(modelWithEmptyTitle.body, 'Test Body');

      // Model with zero id (should still be created)
      final modelWithZeroId = NotificationModel(
        id: 0,
        title: 'Test Title',
        body: 'Test Body',
      );
      expect(modelWithZeroId.id, 0);
    });

    test('ChatNotificationModel creation', () {
      // Valid chat model
      final validChatModel = ChatNotificationModel(
        id: 1,
        title: 'Test Title',
        body: 'Test Body',
        userImageUrl: 'https://example.com/avatar.jpg',
        userName: 'John Doe',
        payload: 'test_payload',
      );
      expect(validChatModel.id, 1);
      expect(validChatModel.title, 'Test Title');
      expect(validChatModel.body, 'Test Body');
      expect(validChatModel.userImageUrl, 'https://example.com/avatar.jpg');
      expect(validChatModel.userName, 'John Doe');
      expect(validChatModel.payload, 'test_payload');

      // Chat model with empty user image URL (should still be created)
      final chatModelWithEmptyImage = ChatNotificationModel(
        id: 1,
        title: 'Test Title',
        body: 'Test Body',
        userImageUrl: '',
        userName: 'John Doe',
      );
      expect(chatModelWithEmptyImage.userImageUrl, '');
      expect(chatModelWithEmptyImage.userName, 'John Doe');

      // Chat model with empty user name (should still be created)
      final chatModelWithEmptyName = ChatNotificationModel(
        id: 1,
        title: 'Test Title',
        body: 'Test Body',
        userImageUrl: 'https://example.com/avatar.jpg',
        userName: '',
      );
      expect(chatModelWithEmptyName.userImageUrl,
          'https://example.com/avatar.jpg');
      expect(chatModelWithEmptyName.userName, '');
    });

    test('NotificationData default values', () {
      const notificationData = NotificationData();

      expect(notificationData.androidNotificationChannel.id,
          'high_importance_channel');
      expect(notificationData.androidNotificationChannel.name,
          'High importance notifications');
      expect(notificationData.initializationSettingsAndroid.defaultIcon,
          '@mipmap/ic_launcher');
    });

    test('NotificationAction classes', () {
      // Test click action
      const clickAction = NotificationClickAction('test_payload');
      expect(clickAction.payload, 'test_payload');

      // Test reply action
      const replyAction = NotificationReplyAction(
        payload: 'test_payload',
        replyText: 'Hello World',
      );
      expect(replyAction.payload, 'test_payload');
      expect(replyAction.replyText, 'Hello World');

      // Test mark as read action
      const markReadAction = NotificationMarkReadAction('test_payload');
      expect(markReadAction.payload, 'test_payload');
    });

    test('PlatformUtils platform detection', () {
      // These tests will depend on the platform they're running on
      expect(PlatformUtils.isWeb, isA<bool>());
      expect(PlatformUtils.isMobile, isA<bool>());
      expect(PlatformUtils.isDesktop, isA<bool>());
      expect(PlatformUtils.supportsChatNotifications, isA<bool>());
      expect(PlatformUtils.supportsNotificationActions, isA<bool>());
    });

    test('NotificationConstants values', () {
      expect(NotificationConstants.actionReceiverPortName,
          'v_action_receiver_port');
      expect(NotificationConstants.defaultChannelId, 'high_importance_channel');
      expect(NotificationConstants.defaultChannelName,
          'High Importance Notifications');
      expect(NotificationConstants.markAsReadActionId, '1');
      expect(NotificationConstants.replyActionId, '2');
      expect(NotificationConstants.defaultMarkAsReadLabel, 'Mark as read');
      expect(NotificationConstants.defaultReplyLabel, 'Reply');
      expect(NotificationConstants.defaultReplyHint, 'Your message...');
    });
  });
}
