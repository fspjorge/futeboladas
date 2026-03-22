import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game.dart';

/// Centraliza todas as operações Firestore sobre a coleção 'games'.
class GameService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  GameService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static final GameService instance = GameService();

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('games');

  // ── Queries ───────────────────────────────────────────────────────────────

  /// Stream de games ativos, ordenados por data.
  Stream<List<Game>> jogosAtivosStream() {
    return _col
        .where('isActive', isEqualTo: true)
        .orderBy('date')
        .snapshots()
        .map((qs) => qs.docs.map(Game.fromQueryDoc).toList());
  }

  /// Stream de um game específico.
  Stream<Game?> jogoStream(String gameId) {
    return _col.doc(gameId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return Game.fromFirestore(doc);
    });
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<String> criarJogo(Game game) async {
    final ref = await _col.add(game.toFirestore());
    return ref.id;
  }

  Future<void> atualizarJogo(Game game) {
    return _col.doc(game.id).update(game.toFirestore());
  }

  /// Apagar o game e todas as suas subcoleções (presencas + admin).
  Future<void> apagarJogo(String gameId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw StateError('Sem sessão iniciada');
      }

      final docRef = _col.doc(gameId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        throw Exception('Game não encontrado no Firestore (ID: $gameId)');
      }

      final data = docSnap.data()!;
      final ownerUid = data['createdBy'] as String?;

      if (ownerUid != user.uid) {
        throw Exception(
          'Não tens permissão para apagar este game (Dono: $ownerUid, Tu: ${user.uid})',
        );
      }

      final batch = _db.batch();

      // 1. Adicionar presenças ao batch
      final presencas = await docRef.collection('attendances').get();
      for (final doc in presencas.docs) {
        batch.delete(doc.reference);
      }

      // 2. Adicionar documento admin ao batch (se existir)
      final adminRef = docRef.collection('admin').doc('privado');
      final adminDoc = await adminRef.get();
      if (adminDoc.exists) {
        batch.delete(adminRef);
      }

      // 3. Adicionar o próprio game ao batch (último)
      batch.delete(docRef);

      await batch.commit();
    } catch (e) {
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          throw Exception(
            'Erro de permissão no Firestore ao apagar o game. Verifica se tu és o criador.',
          );
        }
      }
      rethrow;
    }
  }

  // ── Admin (dados privados do organizador) ─────────────────────────────────

  Stream<Map<String, dynamic>> adminStream(String gameId) {
    return _col
        .doc(gameId)
        .collection('admin')
        .doc('privado')
        .snapshots()
        .map((d) => d.data() ?? {});
  }

  Future<void> guardarAdmin(
    String gameId, {
    required String contactos,
    required String historico,
  }) {
    return _col.doc(gameId).collection('admin').doc('privado').set({
      'contactos': contactos,
      'historico': historico,
    }, SetOptions(merge: true));
  }
}
