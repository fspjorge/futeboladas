import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:futeboladas/widgets/auth/auth_gate.dart';
import 'package:futeboladas/screens/auth/login_page.dart';

void main() {
  group('AuthGate Widget', () {
    testWidgets('shows LoginPage when user is null', (
      WidgetTester tester,
    ) async {
      // Mock FirebaseAuth with null user
      final mockAuth = MockFirebaseAuth(signedIn: false);

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(MaterialApp(home: AuthGate(auth: mockAuth)));
      });

      // We should see a CircularProgressIndicator first
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for stream to emit
      await tester.pumpAndSettle();

      // Since user is null, LoginPage should be rendered
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
