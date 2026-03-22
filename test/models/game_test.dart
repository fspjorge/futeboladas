import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:futeboladas/models/game.dart';

void main() {
  group('Game Model', () {
    test('creates Game from DocumentSnapshot', () async {
      final fakeFirestore = FakeFirebaseFirestore();

      final docData = {
        'title': 'Futebolada Noturna',
        'location': 'Estádio Municipal',
        'players': 10,
        'date': Timestamp.fromDate(DateTime(2023, 10, 10, 20, 0)),
        'participants': ['user1', 'user2'],
        'isActive': true,
        'field': 'Campo 1',
        'price': 5.5,
      };

      final docRef = await fakeFirestore.collection('games').add(docData);
      final snapshot = await docRef.get();

      final game = Game.fromFirestore(snapshot);

      expect(game.id, docRef.id);
      expect(game.title, 'Futebolada Noturna');
      expect(game.location, 'Estádio Municipal');
      expect(game.players, 10);
      expect(game.date, DateTime(2023, 10, 10, 20, 0));
      expect(game.participants, ['user1', 'user2']);
      expect(game.isActive, true);
      expect(game.field, 'Campo 1');
      expect(game.price, 5.5);
    });

    test('toFirestore returns correct Map', () {
      final game = Game(
        id: '123',
        title: 'Futebolada Noturna',
        location: 'Estádio Municipal',
        players: 10,
        date: DateTime(2023, 10, 10, 20, 0),
        participants: ['user1', 'user2'],
        isActive: true,
        field: 'Campo 1',
        price: 5.5,
      );

      final map = game.toFirestore();

      expect(map['title'], 'Futebolada Noturna');
      expect(map['location'], 'Estádio Municipal');
      expect(map['players'], 10);
      expect(map['date'], isA<Timestamp>());
      expect(
        (map['date'] as Timestamp).toDate(),
        DateTime(2023, 10, 10, 20, 0),
      );
      expect(map['participants'], ['user1', 'user2']);
      expect(map['isActive'], true);
      expect(map['field'], 'Campo 1');
      expect(map['price'], 5.5);
    });
  });
}
