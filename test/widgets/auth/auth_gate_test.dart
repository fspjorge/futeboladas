import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:futeboladas/widgets/auth/auth_gate.dart';
import 'package:futeboladas/screens/auth/login_page.dart';
import 'package:futeboladas/screens/home_dashboard.dart';
import 'package:futeboladas/services/auth_service.dart';
import 'package:futeboladas/services/game_service.dart';
import 'package:futeboladas/services/attendance_service.dart';

void main() {
  late MockAuthService mockAuthService;
  late MockGameService mockGameService;
  late MockAttendanceService mockAttendanceService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockGameService = MockGameService();
    mockAttendanceService = MockAttendanceService();
  });

  group('AuthGate Widget', () {
    testWidgets('shows LoginPage when session user is null', (
      WidgetTester tester,
    ) async {
      when(() => mockAuthService.authStateChanges).thenAnswer(
        (_) => Stream.value(const AuthState(AuthChangeEvent.signedOut, null)),
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: AuthGate(
              authService: mockAuthService,
              gameService: mockGameService,
              attendanceService: mockAttendanceService,
            ),
          ),
        );
      });

      await tester.pump();
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('shows HomeDashboard when user is authenticated', (
      WidgetTester tester,
    ) async {
      final mockUser = MockUser();
      final mockSession = MockSession();
      when(() => mockSession.user).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('123');
      when(() => mockUser.email).thenReturn('test@test.com');
      when(() => mockUser.userMetadata).thenReturn({});

      when(() => mockAuthService.authStateChanges).thenAnswer(
        (_) => Stream.value(AuthState(AuthChangeEvent.signedIn, mockSession)),
      );

      // Mock games stream used by HomeDashboard -> GamesList
      when(
        () => mockGameService.jogosAtivosStream(),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => mockAttendanceService.jogosOndeVouStream(),
      ).thenAnswer((_) => Stream.value({}));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: AuthGate(
              authService: mockAuthService,
              gameService: mockGameService,
              attendanceService: mockAttendanceService,
            ),
          ),
        );
      });

      await tester.pump();
      expect(find.byType(HomeDashboard), findsOneWidget);
    });
  });
}

class MockAuthService extends Mock implements AuthService {}

class MockGameService extends Mock implements GameService {}

class MockAttendanceService extends Mock implements AttendanceService {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}
