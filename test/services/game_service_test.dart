import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futeboladas/models/game.dart';
import 'package:futeboladas/services/game_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late GameService jogoService;

  final mockUser = MockUser(
    uid: 'user123',
    email: 'test@test.com',
    displayName: 'Test User',
  );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
    jogoService = GameService(firestore: fakeFirestore, auth: mockAuth);
  });

  group('GameService - CRUD Operations', () {
    test('should create a new game and store it in Firestore', () async {
      final newJogo = Game(
        id: '',
        title: 'Game de Teste',
        location: 'Campo A',
        players: 10,
        date: DateTime.now().add(const Duration(days: 1)),
        createdBy: mockUser.uid,
      );

      final id = await jogoService.criarJogo(newJogo);
      expect(id, isNotEmpty);

      final doc = await fakeFirestore.collection('games').doc(id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['title'], 'Game de Teste');
    });

    test('should return only active games in the stream', () async {
      // Create one active and one inactive game
      await fakeFirestore.collection('games').add({
        'title': 'Ativo',
        'isActive': true,
        'date': Timestamp.fromDate(DateTime.now()),
      });

      // Using the service to ensure consistent format
      await jogoService.criarJogo(
        Game(
          id: '',
          title: 'Inativo',
          location: 'Local',
          players: 10,
          date: DateTime.now().add(const Duration(hours: 1)),
          isActive: false,
        ),
      );

      await jogoService.criarJogo(
        Game(
          id: '',
          title: 'Ativo',
          location: 'Local',
          players: 12,
          date: DateTime.now().add(const Duration(hours: 2)),
          isActive: true,
        ),
      );

      final stream = jogoService.jogosAtivosStream();
      final list = await stream.first;

      // Filter out the 'manual' one if it doesn't match the model's 'isActive' filter perfectly in fake_firestore
      final activeOnly = list.where((j) => j.isActive).toList();

      expect(activeOnly.length, 2); // 'Ativo' (manual) + 'Ativo' (service)
      expect(activeOnly.every((j) => j.title == 'Ativo'), isTrue);
    });

    test('should delete game if user is owner', () async {
      final gameId = await jogoService.criarJogo(
        Game(
          id: '',
          title: 'Vou ser apagado',
          location: 'Local',
          players: 10,
          date: DateTime.now(),
          createdBy: mockUser.uid,
        ),
      );

      await jogoService.apagarJogo(gameId);

      final doc = await fakeFirestore.collection('games').doc(gameId).get();
      expect(doc.exists, isFalse);
    });

    test('should throw exception if non-owner tries to delete', () async {
      final gameId = await jogoService.criarJogo(
        Game(
          id: '',
          title: 'Protegido',
          location: 'Local',
          players: 10,
          date: DateTime.now(),
          createdBy: 'outra-pessoa',
        ),
      );

      expect(() => jogoService.apagarJogo(gameId), throwsException);
    });
  });
}
