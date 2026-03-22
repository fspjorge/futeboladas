import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameDetailPlayers extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> jogoRef;
  final String? createdBy;
  final String uid;

  const GameDetailPlayers({
    super.key,
    required this.jogoRef,
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
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: jogoRef
              .collection('attendances')
              .where('isGoing', isEqualTo: true)
              .snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
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
                  final name = d.data()['name'] as String? ?? 'Jogador';
                  final photo = d.data()['photo'] as String?;
                  final isOrg = d.id == createdBy;

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
