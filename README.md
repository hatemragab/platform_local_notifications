- push local notifications any where in flutter


- for web add OverlaySupport   
```dart

  OverlaySupport.global(
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        darkTheme: ThemeData.dark(),
        home: const Home( ),
      ),
    );

```

## first init
```dart
 await PlatformNotifier.I.init(appName: "test app name");
```

## Request notification permissions
```dart
 bool? isAccepted = await PlatformNotifier.I.requestPermissions();
 print("isAccepted $isAccepted");
```

## to show normal notification 
```dart
  await PlatformNotifier.I.showPluginNotification(
      ShowPluginNotificationModel(
          id: DateTime.now().second,
          title: "title",
          body: "body",
          payload: "test"),
```

## to show chat notifications with action (Reply and mark as read) buttons
```dart
 await PlatformNotifier.I.showChatNotification(
                model: ShowPluginNotificationModel(
                  id: DateTime.now().second,
                  title: "title",
                  body: "body",
                  payload: "test",
                ),
                userImage: "https://thumbs.dreamstime.com/b/default-avatar-profile-vector-user-profile-default-avatar-profile-vector-user-profile-profile-179376714.jpg",
                conversationTitle: "conversationTitle",
                userName: "userName",
              );
```
## Listen for chick and actions stream
```dart
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

```