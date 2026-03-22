import 'package:flutter_test/flutter_test.dart';
import 'package:futeboladas/models/game.dart';

void main() {
  group('Game Model', () {
    test('creates Game from Supabase map', () {
      final docData = {
        'id': '123',
        'title': 'Futebolada Noturna',
        'location': 'Estádio Municipal',
        'players_limit': 10,
        'date': '2023-10-10T20:00:00.000',
        'is_active': true,
        'field': 'Campo 1',
        'price': 5.5,
        'created_by': 'user_abc',
      };

      final game = Game.fromSupabase(docData);

      expect(game.id, '123');
      expect(game.title, 'Futebolada Noturna');
      expect(game.location, 'Estádio Municipal');
      expect(game.players, 10);
      expect(game.date, DateTime(2023, 10, 10, 20, 0));
      expect(game.isActive, true);
      expect(game.field, 'Campo 1');
      expect(game.price, 5.5);
      expect(game.createdBy, 'user_abc');
    });

    test('toSupabase returns correct Map', () {
      final game = Game(
        id: '123',
        title: 'Futebolada Noturna',
        location: 'Estádio Municipal',
        players: 10,
        date: DateTime(2023, 10, 10, 20, 0),
        isActive: true,
        field: 'Campo 1',
        price: 5.5,
        createdBy: 'user_abc',
      );

      final map = game.toSupabase();

      expect(map['title'], 'Futebolada Noturna');
      expect(map['location'], 'Estádio Municipal');
      expect(map['players_limit'], 10);
      expect(map['date'], '2023-10-10T20:00:00.000');
      expect(map['is_active'], true);
      expect(map['field'], 'Campo 1');
      expect(map['price'], 5.5);
      expect(map['created_by'], 'user_abc');
    });
  });
}
