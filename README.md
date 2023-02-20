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
                userImage: "",
                conversationTitle: "conversationTitle",
                userName: "userName",
              );
```
