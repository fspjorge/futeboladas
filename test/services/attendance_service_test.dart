import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:futeboladas/services/attendance_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/supabase_mocks.dart';

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  @override
  Future<U> then<U>(
    FutureOr<U> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) async {
    return onValue([]);
  }
}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late AttendanceService attendanceService;
  late MockSupabaseQueryBuilder mockQueryBuilder;

  setUpAll(() {
    registerFallbackValue(const <String, dynamic>{});
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockQueryBuilder = MockSupabaseQueryBuilder();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('tester');

    attendanceService = AttendanceService(client: mockClient);
  });

  group('AttendanceService Tests', () {
    test('should mark presence successfully', () async {
      const gameId = 'jogo_1';
      final fakeFilterBuilder = FakePostgrestFilterBuilder();

      when(() => mockClient.from('attendances')).thenReturn(mockQueryBuilder);
      when(
        () => mockQueryBuilder.upsert(
          any(),
          onConflict: any(named: 'onConflict'),
        ),
      ).thenReturn(fakeFilterBuilder);

      await attendanceService.markAttendance(gameId, true);

      verify(
        () => mockQueryBuilder.upsert(
          any(
            that: isA<Map<String, dynamic>>()
                .having((m) => m['game_id'], 'game_id', gameId)
                .having((m) => m['is_going'], 'is_going', true),
          ),
          onConflict: 'game_id,user_id',
        ),
      ).called(1);
    });

    test('countConfirmados should return correct amount', () async {
      const gameId = 'jogo_2';
      final mockData = [
        {'game_id': gameId, 'is_going': true},
        {'game_id': gameId, 'is_going': true},
        {'game_id': gameId, 'is_going': false},
        {'game_id': 'other', 'is_going': true},
      ];

      when(() => mockClient.from('attendances')).thenReturn(mockQueryBuilder);

      final mockStreamFilter = MockSupabaseStreamFilterBuilder();
      when(
        () => mockQueryBuilder.stream(primaryKey: any(named: 'primaryKey')),
      ).thenReturn(mockStreamFilter);

      when(() => mockStreamFilter.map(any())).thenAnswer((invocation) {
        final mapper = invocation.positionalArguments[0] as dynamic;
        return Stream.value(mapper(mockData));
      });

      final count = await attendanceService.countConfirmados(gameId).first;
      expect(count, 2);
    });
  });
}
