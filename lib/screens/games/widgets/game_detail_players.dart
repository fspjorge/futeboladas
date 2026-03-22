import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameDetailPlayers extends StatelessWidget {
  final String gameId;
  final String? createdBy;
  final String uid;

  const GameDetailPlayers({
    super.key,
    required this.gameId,
    this.createdBy,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
          child: Text(
            'JOGADORES CONFIRMADOS',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('game_participants_view')
              .stream(primaryKey: ['attendance_id'])
              .map(
                (rows) => rows
                    .where(
                      (r) => r['game_id'] == gameId && r['is_going'] == true,
                    )
                    .toList(),
              ),
          builder: (context, snap) {
            final docs = snap.data ?? [];
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Ninguém confirmou ainda.',
                  style: GoogleFonts.outfit(
                    color: Colors.white24,
                    fontSize: 14,
                  ),
                ),
              );
            }
            return Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(), // Melhor para Column/ListView
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final name = d['name'] as String? ?? 'Jogador';
                  final photo = d['photo_url'] as String?;
                  final userId = d['user_id'] as String?;
                  final isOrg = userId == createdBy;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: photo != null
                              ? NetworkImage(photo)
                              : null,
                          child: photo == null
                              ? const Icon(Icons.person, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: isOrg
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (isOrg)
                          Icon(Icons.verified, size: 14, color: cs.primary),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
