import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:futeboladas/models/game.dart';
import 'package:futeboladas/services/game_service.dart';
import '../helpers/supabase_mocks.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late GameService gameService;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockFilterBuilder;

  setUpAll(() {
    registerFallbackValue(const <String, dynamic>{});
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user123');

    gameService = GameService(client: mockClient);
  });

  group('GameService - CRUD Operations', () {
    test('should create a new game', () async {
      final newJogo = Game(
        id: '',
        title: 'Game de Teste',
        location: 'Campo A',
        players: 10,
        date: DateTime.now().add(const Duration(days: 1)),
        createdBy: 'user123',
      );

      when(() => mockClient.from('games')).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.insert(any())).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.select(any())).thenReturn(mockQueryBuilder);
      when(
        () => mockQueryBuilder.single(),
      ).thenAnswer((_) async => {'id': 'new_id'});

      final id = await gameService.criarJogo(newJogo);
      expect(id, 'new_id');
      verify(() => mockQueryBuilder.insert(any())).called(1);
    });

    test('should return only active games in the stream', () async {
      final mockData = [
        {
          'id': '1',
          'title': 'Ativo',
          'is_active': true,
          'date': '2023-10-10T10:00:00Z',
        },
        {
          'id': '2',
          'title': 'Inativo',
          'is_active': false,
          'date': '2023-10-11T10:00:00Z',
        },
      ];

      when(() => mockClient.from('games')).thenReturn(mockQueryBuilder);

      final mockStreamFilter = MockSupabaseStreamFilterBuilder();
      when(
        () => mockQueryBuilder.stream(primaryKey: any(named: 'primaryKey')),
      ).thenReturn(mockStreamFilter);

      when(() => mockStreamFilter.map(any())).thenAnswer((invocation) {
        final mapper =
            invocation.positionalArguments[0]
                as List<Game> Function(List<Map<String, dynamic>>);
        return Stream.value(mapper(mockData));
      });

      final list = await gameService.jogosAtivosStream().first;
      expect(list.length, 1);
      expect(list.first.title, 'Ativo');
    });

    test('should delete game if user is owner', () async {
      const gameId = '123';
      when(() => mockClient.from('games')).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
      when(
        () => mockFilterBuilder.eq(any(), any()),
      ).thenReturn(mockFilterBuilder);
      // Mocking the Future return of PostgrestFilterBuilder (which delete returns)
      when(() => mockFilterBuilder.then(any())).thenAnswer((invocation) async {
        final callback = invocation.positionalArguments[0] as Function(dynamic);
        return callback([]);
      });

      await gameService.apagarJogo(gameId);
      verify(() => mockQueryBuilder.delete()).called(1);
      verify(() => mockFilterBuilder.eq('id', gameId)).called(1);
    });
  });
}
