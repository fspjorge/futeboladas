import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/jogo.dart';

/// Centraliza todas as operações Firestore sobre a coleção 'jogos'.
class JogoService {
  JogoService._();
  static final JogoService instance = JogoService._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('jogos');

  // ── Queries ───────────────────────────────────────────────────────────────

  /// Stream de jogos ativos, ordenados por data.
  Stream<List<Jogo>> jogosAtivosStream() {
    return _col
        .where('ativo', isEqualTo: true)
        .orderBy('data')
        .snapshots()
        .map((qs) => qs.docs.map(Jogo.fromQueryDoc).toList());
  }

  /// Stream de um jogo específico.
  Stream<Jogo?> jogoStream(String jogoId) {
    return _col.doc(jogoId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Jogo.fromFirestore(doc);
    });
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<String> criarJogo(Jogo jogo) async {
    final ref = await _col.add(jogo.toFirestore());
    return ref.id;
  }

  Future<void> atualizarJogo(Jogo jogo) {
    return _col.doc(jogo.id).update(jogo.toFirestore());
  }

  /// Apagar o jogo e todas as suas subcoleções (presencas + admin).
  Future<void> apagarJogo(String jogoId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Sem sessão iniciada');

      final docRef = _col.doc(jogoId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        throw Exception('Jogo não encontrado no Firestore (ID: $jogoId)');
      }

      final data = docSnap.data()!;
      final ownerUid = data['createdBy'] as String?;

      if (ownerUid != user.uid) {
        throw Exception(
          'Não tens permissão para apagar este jogo (Dono: $ownerUid, Tu: ${user.uid})',
        );
      }

      final batch = _db.batch();

      // 1. Adicionar presenças ao batch
      final presencas = await docRef.collection('presencas').get();
      for (final doc in presencas.docs) {
        batch.delete(doc.reference);
      }

      // 2. Adicionar documento admin ao batch (se existir)
      final adminRef = docRef.collection('admin').doc('privado');
      final adminDoc = await adminRef.get();
      if (adminDoc.exists) {
        batch.delete(adminRef);
      }

      // 3. Adicionar o próprio jogo ao batch (último)
      batch.delete(docRef);

      await batch.commit();
    } catch (e) {
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          throw Exception(
            'Erro de permissão no Firestore ao apagar o jogo. Verifica se tu és o criador.',
          );
        }
      }
      rethrow;
    }
  }

  // ── Admin (dados privados do organizador) ─────────────────────────────────

  Stream<Map<String, dynamic>> adminStream(String jogoId) {
    return _col
        .doc(jogoId)
        .collection('admin')
        .doc('privado')
        .snapshots()
        .map((d) => d.data() ?? {});
  }

  Future<void> guardarAdmin(
    String jogoId, {
    required String contactos,
    required String historico,
  }) {
    return _col.doc(jogoId).collection('admin').doc('privado').set({
      'contactos': contactos,
      'historico': historico,
    }, SetOptions(merge: true));
  }
}
