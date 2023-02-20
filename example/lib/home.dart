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
        onPressed: onPush,
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
                userImage: "",
                conversationTitle: "conversationTitle",
                userName: "userName",
              );
            },
            child: const Text("Chat notification"),
          )
        ],
      ),
    );
  }

  void onPush() async {
    await PlatformNotifier.I.showPluginNotification(
      ShowPluginNotificationModel(
          id: DateTime.now().second,
          title: "title",
          body: "body",
          payload: "test"),
    );
  }

  void _setUpStreams() {
    PlatformNotifier.I.platformNotifierStream.listen(
      (event) {
        print(event.toString());
      },
    );
  }

  void _init() async {
    await PlatformNotifier.I.init(appName: "test app name");
    bool? isAccepted = await PlatformNotifier.I.requestPermissions();
    print("isAccepted $isAccepted");
  }
}
