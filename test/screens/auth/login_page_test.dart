import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:futeboladas/screens/auth/login_page.dart';

void main() {
  group('LoginPage Widget', () {
    testWidgets('renders log in mode by default', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockAuth = MockFirebaseAuth();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(MaterialApp(home: LoginPage(auth: mockAuth)));
      });

      // Assert basic UI elements
      expect(find.text('Entrar com Google'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget); // Switch to generic Entrar

      // Should not find the Name field which is for Register only
      expect(find.text('Nome'), findsNothing);
    });

    testWidgets('switches to register mode', skip: true, (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockAuth = MockFirebaseAuth();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(MaterialApp(home: LoginPage(auth: mockAuth)));
      });

      // Find the toggle button
      final toggleButton = find.text('Regista-te');
      expect(toggleButton, findsOneWidget);

      await tester.ensureVisible(toggleButton);
      await tester.pumpAndSettle();
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Now the Name field should appear
      expect(find.text('Nome'), findsOneWidget);
      expect(find.text('Criar Conta'), findsOneWidget);
    });
  });
}
