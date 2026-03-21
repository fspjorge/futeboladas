import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:futeboladas/models/jogo.dart';

void main() {
  group('Jogo Model', () {
    test('creates Jogo from DocumentSnapshot', () async {
      final fakeFirestore = FakeFirebaseFirestore();

      final docData = {
        'titulo': 'Futebolada Noturna',
        'local': 'Estádio Municipal',
        'jogadores': 10,
        'data': Timestamp.fromDate(DateTime(2023, 10, 10, 20, 0)),
        'participantes': ['user1', 'user2'],
        'ativo': true,
        'campo': 'Campo 1',
        'preco': 5.5,
      };

      final docRef = await fakeFirestore.collection('jogos').add(docData);
      final snapshot = await docRef.get();

      final jogo = Jogo.fromFirestore(snapshot);

      expect(jogo.id, docRef.id);
      expect(jogo.titulo, 'Futebolada Noturna');
      expect(jogo.local, 'Estádio Municipal');
      expect(jogo.jogadores, 10);
      expect(jogo.data, DateTime(2023, 10, 10, 20, 0));
      expect(jogo.participantes, ['user1', 'user2']);
      expect(jogo.ativo, true);
      expect(jogo.campo, 'Campo 1');
      expect(jogo.preco, 5.5);
    });

    test('toFirestore returns correct Map', () {
      final jogo = Jogo(
        id: '123',
        titulo: 'Futebolada Noturna',
        local: 'Estádio Municipal',
        jogadores: 10,
        data: DateTime(2023, 10, 10, 20, 0),
        participantes: ['user1', 'user2'],
        ativo: true,
        campo: 'Campo 1',
        preco: 5.5,
      );

      final map = jogo.toFirestore();

      expect(map['titulo'], 'Futebolada Noturna');
      expect(map['local'], 'Estádio Municipal');
      expect(map['jogadores'], 10);
      expect(map['data'], isA<Timestamp>());
      expect(
        (map['data'] as Timestamp).toDate(),
        DateTime(2023, 10, 10, 20, 0),
      );
      expect(map['participantes'], ['user1', 'user2']);
      expect(map['ativo'], true);
      expect(map['campo'], 'Campo 1');
      expect(map['preco'], 5.5);
    });
  });
}
