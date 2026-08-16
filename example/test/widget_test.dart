import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('renders the notification demo controls', (tester) async {
    await tester.pumpWidget(const MyApp(initializeNotifications: false));

    expect(find.text('Platform Local Notifications'), findsOneWidget);
    expect(find.text('Service Status'), findsOneWidget);
    expect(find.text('Request Permissions'), findsOneWidget);
    expect(find.text('Show Simple Notification'), findsOneWidget);
    expect(find.text('Show Chat Notification'), findsOneWidget);
    expect(find.text('Cancel All Notifications'), findsOneWidget);
  });
}
