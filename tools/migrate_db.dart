import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> migrateDatabase(FirebaseFirestore db) async {
  print('Starting DB Migration...');

  // 1. Migrate Jogos to Games
  final jogosSnapshot = await db.collection('jogos').get();
  for (final doc in jogosSnapshot.docs) {
    final oldData = doc.data();
    final newData = {
      'title': oldData['titulo'],
      'location': oldData['local'],
      'players': oldData['jogadores'],
      'date': oldData['data'],
      'participants': oldData['participantes'] ?? [],
      'isActive': oldData['ativo'] ?? true,
      'field': oldData['campo'],
      'price': oldData['preco'],
      'createdBy': oldData['createdBy'],
      'createdByName': oldData['createdByName'],
      'createdByPhoto': oldData['createdByPhoto'],
      'lat': oldData['lat'],
      'lon': oldData['lon'],
    };

    // Copy to new collection keeping the same document ID
    await db.collection('games').doc(doc.id).set(newData);
    // Delete old document (uncomment when tested)
    // await db.collection('jogos').doc(doc.id).delete();
  }

  // 2. Migrate Presencas to Attendances
  final presencasSnapshot = await db.collection('presencas').get();
  for (final doc in presencasSnapshot.docs) {
    final oldData = doc.data();
    // Assuming schema just copies over, adjust if there are portuguese keys here.
    // Usually 'gameId', 'userId', 'status', 'timestamp'
    final newData = {
      'gameId': oldData['jogoId'] ?? oldData['gameId'],
      'userId': oldData['userId'],
      'status': oldData['status'],
      'timestamp': oldData['timestamp'],
    };

    await db.collection('attendances').doc(doc.id).set(newData);
    // await db.collection('presencas').doc(doc.id).delete();
  }

  print('Migration completed successfully!');
}
