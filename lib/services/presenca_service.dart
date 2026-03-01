import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresencaService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _doc(String jogoId) {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Utilizador não autenticado');
    }
    return _db.collection('jogos').doc(jogoId).collection('presencas').doc(uid);
  }

  Future<void> marcarPresenca(String jogoId, bool vai) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utilizador não autenticado');
    }

    final batch = _db.batch();
    final presenceRef = _doc(jogoId);

    // 1. Atualizar a subcoleção de presenças
    batch.set(presenceRef, {
      'vai': vai,
      'updatedAt': Timestamp.now(),
      'name': user.displayName ?? '',
      'photo': user.photoURL ?? '',
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<int> countConfirmados(String jogoId) {
    return _db
        .collection('jogos')
        .doc(jogoId)
        .collection('presencas')
        .where('vai', isEqualTo: true)
        .snapshots()
        .map((s) => s.size);
  }

  Stream<bool> minhaPresenca(String jogoId) {
    final uid = _uid;
    if (uid == null) {
      // Se não autenticado, devolve sempre false
      return const Stream<bool>.empty();
    }
    return _db
        .collection('jogos')
        .doc(jogoId)
        .collection('presencas')
        .doc(uid)
        .snapshots()
        .map((d) => (d.data()?['vai'] as bool?) ?? false);
  }
}
