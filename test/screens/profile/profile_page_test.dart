import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:futeboladas/screens/profile/profile_page.dart';
import 'package:futeboladas/services/auth_service.dart';

void main() {
  late MockUser mockUser;
  late MockAuthService mockAuthService;

  setUp(() {
    mockUser = MockUser();
    mockAuthService = MockAuthService();

    when(() => mockUser.id).thenReturn('user123');
    when(() => mockUser.email).thenReturn('test@futeboladas.pt');
    when(() => mockUser.userMetadata).thenReturn({'full_name': 'Test Player'});
    when(() => mockUser.appMetadata).thenReturn({'provider': 'email'});
  });

  group('ProfilePage Widget', () {
    testWidgets('renders user profile correctly', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfilePage(user: mockUser, authService: mockAuthService),
          ),
        );
      });

      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Test Player'), findsOneWidget);
      expect(find.text('test@futeboladas.pt'), findsOneWidget);

      expect(find.text('Alterar nome'), findsOneWidget);
      expect(find.text('Terminar Sessão'), findsOneWidget);
    });
  });
}

class MockUser extends Mock implements User {}

class MockAuthService extends Mock implements AuthService {}
