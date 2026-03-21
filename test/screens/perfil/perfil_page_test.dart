import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:futeboladas/screens/perfil/perfil_page.dart';

void main() {
  group('PerfilPage Widget', () {
    testWidgets('renders user profile correctly', (WidgetTester tester) async {
      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'user123',
        email: 'test@futeboladas.pt',
        displayName: 'Test Player',
      );
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: PerfilPage(user: mockUser, auth: mockAuth),
          ),
        );
      });

      // Verify the user profile information is correctly shown
      expect(find.text('Perfil'), findsOneWidget);
      // Wait, there might be 2 "Perfil" texts (title and another place) but we expect at least 1
      expect(find.text('Test Player'), findsOneWidget);
      expect(find.text('test@futeboladas.pt'), findsOneWidget);

      // Verify buttons
      expect(find.text('Alterar nome'), findsOneWidget);
      expect(find.text('Terminar Sessão'), findsOneWidget);
    });
  });
}
