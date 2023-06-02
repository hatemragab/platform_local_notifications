import 'package:flutter/material.dart';
import 'package:platform_local_notifications/platform_local_notifications.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    _init();
    _setUpStreams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onPush(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TextButton(
            onPressed: () async {
              await PlatformNotifier.I.showChatNotification(
                model: ShowPluginNotificationModel(
                  id: DateTime.now().second,
                  title: "title",
                  body: "body",
                  payload: "test",
                ),
                context: context,
                userImage:
                    "https://thumbs.dreamstime.com/b/default-avatar-profile-vector-user-profile-default-avatar-profile-vector-user-profile-profile-179376714.jpg",
                conversationTitle: "conversationTitle",
                userName: "userName",
              );
            },
            child: const Text("Chat notification"),
          ),
          TextButton(
            onPressed: () async {
              bool? isAccepted = await PlatformNotifier.I.requestPermissions();
              print("isAccepted $isAccepted");
            },
            child: const Text("ask for permissions"),
          ),
        ],
      ),
    );
  }

  void onPush(BuildContext context) async {
    await PlatformNotifier.I.showPluginNotification(
        ShowPluginNotificationModel(
          id: DateTime.now().second,
          title: "title",
          body: "body",
          payload: "test",
          macOsDetails: const DarwinNotificationDetails(
            presentSound: true,
            presentAlert: true,
            presentBadge: true,
            badgeNumber: 1,
          ),
        ),
        context);
  }

  void _setUpStreams() {
    PlatformNotifier.I.platformNotifierStream.listen(
      (event) {
        if (event is PluginNotificationClickAction) {
          //handle when user click on the notification
        }
        if (event is PluginNotificationReplyAction) {
          //handle when user choose reply action
        }
        if (event is PluginNotificationMarkRead) {
          //handle when user submit value to reply textile
        }
      },
    );
  }

  void _init() async {
    await PlatformNotifier.I.init(appName: "test app name");
  }
}
