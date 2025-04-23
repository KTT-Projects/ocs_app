// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocs_app/main.dart';
import 'package:ocs_app/services/api_client.dart';
import 'package:ocs_app/pages/home_page.dart';
import 'package:ocs_app/pages/login_page.dart';

void main() {
  group('App Authentication Tests', () {
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient();
    });

    testWidgets('App starts with login page when no token exists', (WidgetTester tester) async {
      // Start the app with no token
      await tester.pumpWidget(MyApp(apiClient: apiClient));
      await tester.pumpAndSettle(); // Wait for all animations to complete

      // Verify that we see the login form
      expect(find.byType(TextFormField), findsWidgets); // Should find email and password fields
      expect(find.text('Sign In'), findsOneWidget); // Should find the sign in button
      expect(find.byType(HomePage), findsNothing); // Should not find the home page
    });

    testWidgets('App starts with home page when token exists', (WidgetTester tester) async {
      // Simulate an existing token
      await apiClient.setToken('test_token');
      
      // Start the app
      await tester.pumpWidget(MyApp(apiClient: apiClient));
      await tester.pumpAndSettle();

      // Verify that we skip login and go straight to home
      expect(find.byType(HomePage), findsOneWidget); // Should find the home page
      expect(find.byType(LoginPage), findsNothing); // Should not find the login page
    });

    testWidgets('Logout clears token and returns to login page', (WidgetTester tester) async {
      // Start with a token
      await apiClient.setToken('test_token');
      await tester.pumpWidget(MyApp(apiClient: apiClient));
      await tester.pumpAndSettle();

      // Open drawer and tap logout
      await tester.dragFrom(const Offset(20, 200), const Offset(300, 200)); // Open drawer
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Verify we're back at login and token is cleared
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      expect(apiClient.token, isNull);
    });
  });
}
