import 'package:flutter/material.dart';
import 'package:platform_local_notifications/platform_local_notifications.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isInitialized = false;
  String _lastAction = 'No actions yet';
  String _launchDetails = 'No launch details';

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _setupNotificationListeners();
  }

  @override
  void dispose() {
    PlatformNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Local Notifications'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildActionButtons(),
              const SizedBox(height: 16),
              _buildLastActionCard(),
              const SizedBox(height: 16),
              _buildLaunchDetailsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _isInitialized ? Icons.check_circle : Icons.error,
                  color: _isInitialized ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isInitialized ? 'Initialized' : 'Not Initialized',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isInitialized ? _requestPermissions : null,
          icon: const Icon(Icons.notifications),
          label: const Text('Request Permissions'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isInitialized ? _showSimpleNotification : null,
          icon: const Icon(Icons.notification_important),
          label: const Text('Show Simple Notification'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isInitialized ? _showChatNotification : null,
          icon: const Icon(Icons.chat),
          label: const Text('Show Chat Notification'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isInitialized ? _showCustomNotification : null,
          icon: const Icon(Icons.settings),
          label: const Text('Show Custom Notification'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isInitialized ? _cancelAllNotifications : null,
          icon: const Icon(Icons.clear_all),
          label: const Text('Cancel All Notifications'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isInitialized ? _checkAppLaunchDetails : null,
          icon: const Icon(Icons.launch),
          label: const Text('Check Launch Details'),
        ),
      ],
    );
  }

  Widget _buildLastActionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last Action', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_lastAction, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeNotifications() async {
    try {
      await PlatformNotifier.initialize(appName: 'Platform Notifications Demo');
      setState(() {
        _isInitialized = true;
      });
      _updateLastAction('Service initialized successfully');

      // Check if app was launched from notification
      await _checkAppLaunchDetails();
    } catch (error) {
      _updateLastAction('Failed to initialize: $error');
    }
  }

  void _setupNotificationListeners() {
    PlatformNotifier.actionStream.listen((action) {
      switch (action.runtimeType) {
        case NotificationClickAction _:
          final clickAction = action as NotificationClickAction;
          _updateLastAction('Notification clicked: ${clickAction.payload}');
          break;

        case NotificationReplyAction _:
          final replyAction = action as NotificationReplyAction;
          _updateLastAction(
            'User replied: "${replyAction.replyText}" (Payload: ${replyAction.payload})',
          );
          break;

        case NotificationMarkReadAction _:
          final markReadAction = action as NotificationMarkReadAction;
          _updateLastAction(
            'Notification marked as read: ${markReadAction.payload}',
          );
          break;
      }
    });
  }

  Future<void> _requestPermissions() async {
    try {
      final isGranted = await PlatformNotifier.requestPermissions();
      _updateLastAction(
        isGranted == true
            ? 'Notification permissions granted'
            : 'Notification permissions denied',
      );
    } catch (error) {
      _updateLastAction('Failed to request permissions: $error');
    }
  }

  Future<void> _showSimpleNotification() async {
    try {
      final notificationModel = NotificationModel(
        id: DateTime.now().microsecond,
        title: 'Hello! 👋',
        body: 'This is a simple notification from the demo app.',
        payload: 'simple_notification_${DateTime.now().millisecondsSinceEpoch}',
      );

      await PlatformNotifier.showNotification(model: notificationModel);
      _updateLastAction('Simple notification sent');
    } catch (error) {
      _updateLastAction('Failed to show notification: $error');
    }
  }

  Future<void> _showChatNotification() async {
    try {
      final chatModel = ChatNotificationModel(
        id: DateTime.now().microsecond,
        title: 'New Message 💬',
        body: 'Hello! How are you doing today?',
        userImageUrl:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        userName: 'John Doe',
        conversationTitle: 'Team Chat',
        markAsReadLabel: 'Mark as Read',
        replyLabel: 'Quick Reply',
        replyHint: 'Type your reply...',
        payload: 'chat_notification_${DateTime.now().millisecondsSinceEpoch}',
      );

      await PlatformNotifier.showChatNotification(model: chatModel);
      _updateLastAction('Chat notification sent');
    } catch (error) {
      _updateLastAction('Failed to show chat notification: $error');
    }
  }

  Future<void> _showCustomNotification() async {
    try {
      final notificationModel = NotificationModel(
        id: DateTime.now().microsecond,
        title: 'Custom Notification 🎨',
        body: 'This notification has custom styling and configuration.',
        payload: 'custom_notification_${DateTime.now().millisecondsSinceEpoch}',
        androidDetails: AndroidNotificationDetails(
          'custom_channel',
          'Custom Notifications',
          channelDescription: 'Channel for custom notifications',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iosDetails: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
        ),
        macOsDetails: const DarwinNotificationDetails(
          presentSound: true,
          subtitle: 'Custom Subtitle',
          presentBadge: true,
        ),
      );

      await PlatformNotifier.showNotification(model: notificationModel);
      _updateLastAction('Custom notification sent');
    } catch (error) {
      _updateLastAction('Failed to show custom notification: $error');
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      await PlatformNotifier.cancelAllNotifications();
      _updateLastAction('All notifications cancelled');
    } catch (error) {
      _updateLastAction('Failed to cancel notifications: $error');
    }
  }

  void _updateLastAction(String action) {
    setState(() {
      _lastAction = '${DateTime.now().toString().substring(11, 19)}: $action';
    });
  }

  Widget _buildLaunchDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Launch Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_launchDetails, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Future<void> _checkAppLaunchDetails() async {
    try {
      final launchDetails = await PlatformNotifier.appLaunchNotification;

      if (launchDetails != null) {
        setState(() {
          _launchDetails =
              'App launched from notification!\n'
              'Did notification launch app: ${launchDetails.didNotificationLaunchApp}\n'
              'Payload: ${launchDetails.notificationResponse?.payload ?? 'No payload'}\n'
              'Action ID: ${launchDetails.notificationResponse?.actionId ?? 'No action'}\n'
              'Input: ${launchDetails.notificationResponse?.input ?? 'No input'}';
        });
        _updateLastAction(
          'Launch details checked - App was launched from notification',
        );
      } else {
        setState(() {
          _launchDetails = 'App was not launched from a notification';
        });
        _updateLastAction(
          'Launch details checked - App was not launched from notification',
        );
      }
    } catch (error) {
      setState(() {
        _launchDetails = 'Error checking launch details: $error';
      });
      _updateLastAction('Failed to check launch details: $error');
    }
  }
}
