import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AttendanceService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _doc(String gameId) {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Utilizador não autenticado');
    }
    return _db
        .collection('games')
        .doc(gameId)
        .collection('attendances')
        .doc(uid);
  }

  Future<void> markAttendance(String gameId, bool isGoing) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utilizador não autenticado');
    }

    final batch = _db.batch();
    final presenceRef = _doc(gameId);

    // 1. Atualizar a subcoleção de presenças
    batch.set(presenceRef, {
      'isGoing': isGoing,
      'updatedAt': Timestamp.now(),
      'name': user.displayName ?? '',
      'photo': user.photoURL ?? '',
      'uid': user.uid, // ← adiciona este field
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<int> countConfirmados(String gameId) {
    return _db
        .collection('games')
        .doc(gameId)
        .collection('attendances')
        .where('isGoing', isEqualTo: true)
        .snapshots()
        .map((s) => s.size);
  }

  Stream<bool> minhaPresenca(String gameId) {
    final uid = _uid;
    if (uid == null) {
      // Se não autenticado, devolve sempre false
      return const Stream<bool>.empty();
    }
    return _db
        .collection('games')
        .doc(gameId)
        .collection('attendances')
        .doc(uid)
        .snapshots()
        .map((d) => (d.data()?['isGoing'] as bool?) ?? false);
  }

  Stream<Set<String>> jogosOndeVouStream() {
    final uid = _uid;
    if (uid == null) return Stream.value({});

    return _db
        .collectionGroup('attendances')
        .where('uid', isEqualTo: uid)
        .where('isGoing', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => d.reference.parent.parent!.id).toSet(),
        );
  }
}
