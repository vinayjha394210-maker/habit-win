// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_win/main.dart';
import 'package:habit_win/services/notification_service.dart'; // Import NotificationService

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Initialize NotificationService for the test environment
    final NotificationService notificationService = NotificationService();
    // For widget tests, a mock navigator key is sufficient as we're not testing navigation itself
    await notificationService.init(GlobalKey<NavigatorState>());

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(notificationService: notificationService));

    // Verify that the app starts and displays the MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
    // Further specific checks can be added here if needed, e.g.,
    // expect(find.byType(HomeScreen), findsOneWidget);
    // expect(find.text('TODAY'), findsOneWidget); // Example text from HomeScreen
  });
}
