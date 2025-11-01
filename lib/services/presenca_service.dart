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
    await _doc(jogoId).set({
      'vai': vai,
      'updatedAt': FieldValue.serverTimestamp(),
      'name': user.displayName,
      'photo': user.photoURL,
    }, SetOptions(merge: true));
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


