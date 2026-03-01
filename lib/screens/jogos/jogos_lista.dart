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

enum FilterMode { todos, meus, participo }

class _JogosListaState extends State<JogosLista> {
  DateTime? _selectedDay;
  FilterMode _filterMode = FilterMode.todos;

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
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.sports_soccer,
            message: 'Sem jogos agendados.',
            cs: cs,
          );
        }

        final docs = snapshot.data!.docs;
        final filtered = _processGames(docs, uid);

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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Horizontal Day Selector
            _buildDaySelector(filtered.keys.toList()..sort(), cs),
            const SizedBox(height: 20),
            // Filter Chips
            _buildFilterChips(cs),
            const SizedBox(height: 24),
            // Game Timeline/List
            if (visibleDays.isEmpty)
              _buildEmptyState(
                icon: Icons.filter_alt_off_outlined,
                message: 'Nenhum jogo encontrado para estes filtros.',
                isSmall: true,
                cs: cs,
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

  Map<DateTime, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _processGames(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String? uid,
  ) {
    final Map<DateTime, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    groups = {};

    for (final d in docs) {
      final data = d.data();

      // Aplicar filtros
      if (uid != null) {
        if (_filterMode == FilterMode.meus && data['createdBy'] != uid) {
          continue;
        }
        if (_filterMode == FilterMode.participo) {
          final participants = List<String>.from(data['participantes'] ?? []);
          final isCreator = data['createdBy'] == uid;
          if (!participants.contains(uid) && !isCreator) continue;
        }
      }

      final dt = (data['data'] as Timestamp).toDate();
      final day = DateTime(dt.year, dt.month, dt.day);
      groups.putIfAbsent(day, () => []).add(d);
    }

    return groups;
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(height: 16),
          Text(
            'A carregar jogos...',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const SizedBox(height: 16),
          const Text(
            'Erro ao carregar jogos.',
            style: TextStyle(color: Colors.white70),
          ),
          TextButton(
            onPressed: () => setState(() {}),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required ColorScheme cs,
    bool isSmall = false,
  }) {
    String finalMessage = message;
    if (isSmall) {
      if (_filterMode == FilterMode.meus) {
        finalMessage = 'Não criaste jogos para este dia.';
      } else if (_filterMode == FilterMode.participo) {
        finalMessage = 'Não tens jogos agendados onde vais participar.';
      }
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isSmall ? 40 : 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isSmall ? 40 : 64, color: Colors.white10),
            const SizedBox(height: 16),
            Text(
              finalMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16),
            ),
            if (isSmall && _filterMode != FilterMode.todos)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: () => setState(() {
                    _filterMode = FilterMode.todos;
                    _selectedDay = null;
                  }),
                  child: Text(
                    'VER TODOS OS JOGOS',
                    style: TextStyle(color: cs.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector(List<DateTime> allDays, ColorScheme cs) {
    if (allDays.isEmpty) return const SizedBox.shrink();

    // Determinar o mês predominante para mostrar no topo
    final monthDisplay = _selectedDay != null
        ? DateFormat('MMMM yyyy', 'pt_PT').format(_selectedDay!).toUpperCase()
        : DateFormat('MMMM yyyy', 'pt_PT').format(allDays.first).toUpperCase();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            monthDisplay,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: cs.primary.withOpacity(0.5),
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(
          height: 85,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allDays.length,
            itemBuilder: (context, i) {
              final day = allDays[i];
              final isToday = day.isAtSameMomentAs(today);
              final selected =
                  _selectedDay != null &&
                  day.year == _selectedDay!.year &&
                  day.month == _selectedDay!.month &&
                  day.day == _selectedDay!.day;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () =>
                      setState(() => _selectedDay = selected ? null : day),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary
                          : isToday
                          ? cs.primary.withOpacity(0.1)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? cs.primary
                            : isToday
                            ? cs.primary.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                        width: isToday ? 2 : 1.5,
                      ),
                      boxShadow: [
                        if (selected)
                          BoxShadow(
                            color: cs.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isToday && !selected)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          DateFormat.d('pt_PT').format(day),
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? const Color(0xFF0F172A)
                                : isToday
                                ? cs.primary
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
                                : isToday
                                ? cs.primary.withOpacity(0.7)
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
        ),
      ],
    );
  }

  Widget _buildFilterChips(ColorScheme cs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            'Todos',
            _filterMode == FilterMode.todos,
            () => setState(() {
              _filterMode = FilterMode.todos;
              _selectedDay = null; // Limpar dia ao trocar filtro
            }),
            cs,
          ),
          const SizedBox(width: 8),
          _filterChip(
            'Meus',
            _filterMode == FilterMode.meus,
            () => setState(() {
              _filterMode = FilterMode.meus;
              _selectedDay = null; // Limpar dia ao trocar filtro
            }),
            cs,
          ),
          const SizedBox(width: 8),
          _filterChip(
            'Vou',
            _filterMode == FilterMode.participo,
            () => setState(() {
              _filterMode = FilterMode.participo;
              _selectedDay = null; // Limpar dia ao trocar filtro
            }),
            cs,
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    bool selected,
    VoidCallback onTap,
    ColorScheme cs, {
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? cs.primary.withOpacity(0.6)
                : Colors.white.withOpacity(0.1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? cs.primary : Colors.white38,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w900 : FontWeight.bold,
                color: selected ? cs.primary : Colors.white60,
              ),
            ),
          ],
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
                          fontSize: 18,
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
                            final restantes = maxJogadores - confirmados;
                            final bool hasLimit = maxJogadores > 0;
                            final bool isFull =
                                hasLimit && confirmados >= maxJogadores;

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    _buildStatusIndicator(
                                      confirmados,
                                      maxJogadores,
                                      cs,
                                    ),
                                    if (hasLimit && restantes > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
                                        child: Text(
                                          'Faltam $restantes',
                                          style: TextStyle(
                                            color: cs.primary.withOpacity(0.5),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    const Spacer(),
                                    if (uid != null)
                                      StreamBuilder<bool>(
                                        stream: presencas.minhaPresenca(jogoId),
                                        builder: (context, meSnap) {
                                          final isGoing = meSnap.data ?? false;
                                          return _buildJoinButton(
                                            isGoing,
                                            isFull,
                                            () async {
                                              try {
                                                if (!isGoing && isFull) {
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
                                ),
                                if (hasLimit)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: _buildProgressBar(
                                      confirmados,
                                      maxJogadores,
                                      cs,
                                    ),
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

  Widget _buildProgressBar(int current, int max, ColorScheme cs) {
    final double progress = (current / max).clamp(0.0, 1.0);
    final bool isFull = current >= max;

    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: isFull ? cs.error : cs.primary.withOpacity(0.8),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              if (!isFull)
                BoxShadow(
                  color: cs.primary.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
            ],
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

    return Container(
      constraints: const BoxConstraints(
        minWidth: 70, // Largura mínima
        maxWidth: 100, // Largura máxima
      ),
      child: ElevatedButton(
        onPressed: isFull ? null : onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          minimumSize: Size.zero,
          backgroundColor: isFull ? Colors.white10 : cs.primary,
          foregroundColor: isFull ? Colors.white24 : const Color(0xFF0F172A),
        ),
        child: Text(
          isFull ? 'LOTADO' : 'VOU',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
