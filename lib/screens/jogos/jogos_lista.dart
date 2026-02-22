import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'jogo_detalhe.dart';
import 'confirmacao_page.dart';
import '../../services/presenca_service.dart';

class JogosLista extends StatefulWidget {
  const JogosLista({super.key});

  @override
  State<JogosLista> createState() => _JogosListaState();
}

class _JogosListaState extends State<JogosLista> {
  DateTime? _selectedDay;
  bool _onlyMine = false;

  @override
  Widget build(BuildContext context) {
    final presencas = PresencaService();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('jogos')
          .where('ativo', isEqualTo: true)
          .orderBy('data')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Erro ao carregar jogos',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Icon(Icons.sports_soccer, size: 48, color: Colors.white10),
                  const SizedBox(height: 16),
                  Text(
                    'Sem jogos agendados.',
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final Map<DateTime, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        groups = {};
        for (final d in docs) {
          final dt = (d.data()['data'] as Timestamp).toDate();
          final day = DateTime(dt.year, dt.month, dt.day);
          groups.putIfAbsent(day, () => []).add(d);
        }
        final allDays = groups.keys.toList()..sort();

        // Aplicar filtros de propriedade/participação (se necessário expandir no futuro)
        final Map<DateTime, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        filtered = {};
        for (final d in allDays) {
          final list = groups[d]!;
          final mine = _onlyMine && uid != null
              ? list
                    .where((x) => (x.data()['createdBy'] as String?) == uid)
                    .toList()
              : list;
          if (mine.isNotEmpty) filtered[d] = mine;
        }

        final filteredDays = filtered.keys.toList()..sort();
        final visibleDays = _selectedDay == null
            ? filteredDays
            : filteredDays
                  .where(
                    (d) =>
                        d.year == _selectedDay!.year &&
                        d.month == _selectedDay!.month &&
                        d.day == _selectedDay!.day,
                  )
                  .toList();

        return Column(
          children: [
            // Horizontal Day Selector
            _buildDaySelector(allDays, cs),
            const SizedBox(height: 20),
            // Filter Chips
            _buildFilterChips(cs),
            const SizedBox(height: 24),
            // Game Timeline/List
            if (visibleDays.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Nenhum jogo encontrado para os filtros selecionados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38),
                ),
              )
            else
              ...visibleDays.map(
                (day) =>
                    _buildDaySection(day, filtered[day]!, presencas, uid, cs),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDaySelector(List<DateTime> allDays, ColorScheme cs) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allDays.length,
        itemBuilder: (context, i) {
          final day = allDays[i];
          final selected =
              _selectedDay != null &&
              day.year == _selectedDay!.year &&
              day.month == _selectedDay!.month &&
              day.day == _selectedDay!.day;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedDay = selected ? null : day),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                decoration: BoxDecoration(
                  color: selected ? cs.primary : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? cs.primary
                        : Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat.d('pt_PT').format(day),
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: selected
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                      ),
                    ),
                    Text(
                      DateFormat.E('pt_PT').format(day).toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? const Color(0xFF0F172A).withOpacity(0.7)
                            : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme cs) {
    return Row(
      children: [
        _filterChip(
          'Todos',
          !_onlyMine,
          () => setState(() => _onlyMine = false),
          cs,
        ),
        const SizedBox(width: 8),
        _filterChip(
          'Meus Jogos',
          _onlyMine,
          () => setState(() => _onlyMine = true),
          cs,
        ),
      ],
    );
  }

  Widget _filterChip(
    String label,
    bool selected,
    VoidCallback onTap,
    ColorScheme cs,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? cs.primary.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: selected ? cs.primary : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildDaySection(
    DateTime day,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> items,
    PresencaService presencas,
    String? uid,
    ColorScheme cs,
  ) {
    items.sort((a, b) {
      final da = (a.data()['data'] as Timestamp).toDate();
      final db = (b.data()['data'] as Timestamp).toDate();
      return da.compareTo(db);
    });

    final dayStr = DateFormat("EEEE, d 'de' MMMM", 'pt_PT').format(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16, top: 8),
          child: Text(
            dayStr.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white38,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items.map((doc) => _buildGameCard(doc, presencas, uid, cs)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildGameCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    PresencaService presencas,
    String? uid,
    ColorScheme cs,
  ) {
    final data = doc.data();
    final local = data['local'] as String? ?? 'Local desconhecido';
    final maxJogadores = (data['jogadores'] as num?)?.toInt() ?? 0;
    final date = (data['data'] as Timestamp).toDate();
    final jogoId = doc.id;
    final organizer = data['createdByName'] as String? ?? 'Desconhecido';
    final hora = DateFormat('HH:mm').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => JogoDetalhe(jogoId: jogoId)),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  // Time side bar
                  Column(
                    children: [
                      Text(
                        hora,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 30,
                        height: 3,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          local,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.white38,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                organizer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<int>(
                          stream: presencas.countConfirmados(jogoId),
                          builder: (context, countSnap) {
                            final confirmados = countSnap.data ?? 0;
                            final full =
                                maxJogadores > 0 && confirmados >= maxJogadores;

                            return Row(
                              children: [
                                _buildStatusIndicator(
                                  confirmados,
                                  maxJogadores,
                                  cs,
                                ),
                                const Spacer(),
                                if (uid != null)
                                  StreamBuilder<bool>(
                                    stream: presencas.minhaPresenca(jogoId),
                                    builder: (context, meSnap) {
                                      final isGoing = meSnap.data ?? false;
                                      return _buildJoinButton(
                                        isGoing,
                                        full,
                                        () async {
                                          try {
                                            if (!isGoing && full) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Este jogo já está lotado!',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            await presencas.marcarPresenca(
                                              jogoId,
                                              !isGoing,
                                            );
                                            if (!isGoing && mounted) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ConfirmacaoJogoPage(
                                                        titulo: local,
                                                        data: date,
                                                        local: local,
                                                      ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('Erro: $e'),
                                              ),
                                            );
                                          }
                                        },
                                        cs,
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(int current, int max, ColorScheme cs) {
    final bool hasLimit = max > 0;
    final bool isFull = hasLimit && current >= max;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isFull ? cs.error.withOpacity(0.1) : cs.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_alt_rounded,
            size: 14,
            color: isFull ? cs.error : cs.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '$current${hasLimit ? "/$max" : ""}',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isFull ? cs.error : cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton(
    bool isGoing,
    bool isFull,
    VoidCallback onTap,
    ColorScheme cs,
  ) {
    if (isGoing) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          side: const BorderSide(color: Colors.white24),
          foregroundColor: Colors.white70,
        ),
        child: const Text('SAIR'),
      );
    }

    return ElevatedButton(
      onPressed: isFull ? null : onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        minimumSize: Size.zero,
        backgroundColor: isFull ? Colors.white10 : cs.primary,
        foregroundColor: isFull ? Colors.white24 : const Color(0xFF0F172A),
      ),
      child: Text(isFull ? 'LOTADO' : 'VOU'),
    );
  }
}
