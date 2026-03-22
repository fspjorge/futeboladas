import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceService {
  final SupabaseClient _supabase;

  AttendanceService({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  String? get _uid => _supabase.auth.currentUser?.id;

  Future<void> markAttendance(String gameId, bool isGoing) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Utilizador não autenticado');
    }

    try {
      // Usamos upsert com onConflict para garantir que atualizamos se já existir
      await _supabase.from('attendances').upsert({
        'game_id': gameId,
        'user_id': uid,
        'is_going': isGoing,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'game_id,user_id');

      debugPrint(
        'AttendanceService: Presença atualizada com sucesso para $gameId ($isGoing)',
      );
    } catch (e) {
      debugPrint('AttendanceService: Erro ao marcar presença: $e');
      rethrow;
    }
  }

  Stream<int> countConfirmados(String gameId) {
    return _supabase
        .from('attendances')
        .stream(primaryKey: ['id'])
        .map(
          (list) => list
              .where(
                (row) => row['game_id'] == gameId && row['is_going'] == true,
              )
              .length,
        );
  }

  Stream<bool> minhaPresenca(String gameId) {
    final uid = _uid;
    if (uid == null) return Stream.value(false);

    // Ouvimos todas as mudanças na tabela para este utilizador e jogo
    return _supabase.from('attendances').stream(primaryKey: ['id']).map((list) {
      final row = list.where(
        (r) => r['game_id'] == gameId && r['user_id'] == uid,
      );
      if (row.isEmpty) return false;
      final going = row.first['is_going'] == true;
      return going;
    });
  }

  Stream<Set<String>> jogosOndeVouStream() {
    final uid = _uid;
    if (uid == null) return Stream.value({});

    return _supabase
        .from('attendances')
        .stream(primaryKey: ['id'])
        .map(
          (list) => list
              .where((r) => r['user_id'] == uid && r['is_going'] == true)
              .map((d) => d['game_id'].toString())
              .toSet(),
        );
  }
}
