import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game.dart';

/// Centraliza todas as operações Supabase sobre a tabela 'games'.
class GameService {
  final SupabaseClient _supabase;

  GameService({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  static final GameService instance = GameService();

  SupabaseQueryBuilder get _table => _supabase.from('games');

  // ── Queries ───────────────────────────────────────────────────────────────

  /// Stream de games ativos, ordenados por data.
  Stream<List<Game>> jogosAtivosStream() {
    return _table
        .stream(primaryKey: ['id'])
        .map(
          (list) =>
              list
                  .where((row) => row['is_active'] == true)
                  .map(Game.fromSupabase)
                  .toList()
                ..sort((a, b) => a.date.compareTo(b.date)),
        );
  }

  /// Stream de um game específico.
  Stream<Game?> jogoStream(String gameId) {
    return _table
        .stream(primaryKey: ['id'])
        .eq('id', gameId)
        .map((list) => list.isEmpty ? null : Game.fromSupabase(list.first));
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<String> criarJogo(Game game) async {
    final data = await _table.insert(game.toSupabase()).select('id').single();
    return data['id'].toString();
  }

  Future<void> atualizarJogo(Game game) async {
    await _table.update(game.toSupabase()).eq('id', game.id);
  }

  /// Apagar o game. O RLS e as FKs (ON DELETE CASCADE) tratam das dependências.
  Future<void> apagarJogo(String gameId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw StateError('Sem sessão iniciada');
      }

      // No Supabase, se o RLS estiver bem configurado, o delete falhará
      // se o utilizador não for o dono.
      await _table.delete().eq('id', gameId);
    } catch (e) {
      rethrow;
    }
  }

  // ── Admin (dados privados do organizador) ─────────────────────────────────

  Future<Game?> getJogo(String gameId) async {
    final response = await _supabase
        .from('games')
        .select()
        .eq('id', gameId)
        .maybeSingle();

    if (response == null) return null;
    return Game.fromSupabase(response);
  }

  Stream<Map<String, dynamic>> adminStream(String gameId) {
    return _supabase
        .from('game_admin')
        .stream(primaryKey: ['game_id'])
        .eq('game_id', gameId)
        .map((list) => list.isEmpty ? {} : list.first);
  }

  Future<void> guardarAdmin(
    String gameId, {
    required String contactos,
    required String historico,
  }) async {
    await _supabase.from('game_admin').upsert({
      'game_id': gameId,
      'contactos': contactos,
      'historico': historico,
    });
  }
}
