import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:futeboladas/screens/auth/login_page.dart';
import 'package:futeboladas/services/auth_service.dart';

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  group('LoginPage Widget', () {
    testWidgets('renders log in mode by default', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );
      });

      expect(find.text('Entrar com Google'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Nome'), findsNothing);
    });

    testWidgets('switches to register mode', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );
      });

      final toggleButton = find.text('Regista-te');
      expect(toggleButton, findsOneWidget);

      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(find.text('Nome'), findsOneWidget);
      expect(find.text('Criar Conta'), findsOneWidget);
    });
  });
}

class MockAuthService extends Mock implements AuthService {}
