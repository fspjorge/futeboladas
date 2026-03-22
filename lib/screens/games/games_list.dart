import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/filter_mode.dart';
import '../../services/attendance_service.dart';
import '../../widgets/empty_state.dart';
import 'widgets/game_card.dart';
import 'widgets/day_selector.dart';
import 'widgets/filter_sheet.dart';

class GamesList extends StatefulWidget {
  final String searchQuery;
  const GamesList({super.key, this.searchQuery = ''});

  @override
  State<GamesList> createState() => _JogosListaState();
}

class _JogosListaState extends State<GamesList> {
  FilterMode _filterMode = FilterMode.all;
  DateTime? _selectedDay;
  String? _selectedCampo;

  bool get _hasActiveFilter =>
      _filterMode != FilterMode.all ||
      _selectedDay != null ||
      _selectedCampo != null;

  void _openFilterSheet(BuildContext context, ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(
        currentMode: _filterMode,
        selectedCampo: _selectedCampo,
        hasActiveFilter: _hasActiveFilter,
        onModeChanged: (mode) => setState(() => _filterMode = mode),
        onCampoChanged: (field) => setState(() => _selectedCampo = field),
        onClearFilters: () => setState(() {
          _filterMode = FilterMode.all;
          _selectedDay = null;
          _selectedCampo = null;
        }),
      ),
    );
  }

  Map<DateTime, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _processGames(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String? uid,
    Set<String> jogosOndeVou,
  ) {
    final Map<DateTime, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    groups = {};

    for (final d in docs) {
      final data = d.data();

      // Filtro de pesquisa
      if (widget.searchQuery.isNotEmpty) {
        final q = widget.searchQuery.toLowerCase();
        final title = (data['title'] as String? ?? '').toLowerCase();
        final location = (data['location'] as String? ?? '').toLowerCase();
        if (!title.contains(q) && !location.contains(q)) continue;
      }

      if (uid != null) {
        if (_filterMode == FilterMode.mine && data['createdBy'] != uid) {
          continue;
        }
        if (_filterMode == FilterMode.attending &&
            !jogosOndeVou.contains(d.id)) {
          continue;
        }
        if (_filterMode == FilterMode.free) {
          final price = data['price'] as num? ?? 0;
          if (price > 0) {
            continue;
          }
        }
      }

      if (_selectedCampo != null) {
        if (data['field'] != _selectedCampo) continue;
      }

      if (_selectedDay != null) {
        final dt = (data['date'] as Timestamp).toDate();
        final day = DateTime(dt.year, dt.month, dt.day);
        if (day != _selectedDay) continue;
      }

      final dt = (data['date'] as Timestamp).toDate();
      final day = DateTime(dt.year, dt.month, dt.day);
      groups.putIfAbsent(day, () => []).add(d);
    }

    return groups;
  }

  List<DateTime> _getAllDays(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final Set<DateTime> days = {};
    for (final d in docs) {
      final dt = (d.data()['date'] as Timestamp).toDate();
      days.add(DateTime(dt.year, dt.month, dt.day));
    }
    return days.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final presencas = AttendanceService();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<Set<String>>(
      stream: presencas.jogosOndeVouStream(),
      builder: (context, vouSnap) {
        final jogosOndeVou = vouSnap.data ?? {};

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('games')
              .where('isActive', isEqualTo: true)
              .orderBy('date')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const Text('Erro ao carregar jogos'),
                    TextButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            final allDays = _getAllDays(docs);
            final filtered = _processGames(docs, uid, jogosOndeVou);
            final visibleDays = filtered.keys.toList()..sort();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DaySelector(
                        allDays: allDays,
                        selectedDay: _selectedDay,
                        onDaySelected: (day) =>
                            setState(() => _selectedDay = day),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: _FilterButton(
                        hasActiveFilter: _hasActiveFilter,
                        onTap: () => _openFilterSheet(context, cs),
                        cs: cs,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (docs.isEmpty)
                  EmptyState(
                    icon: Icons.sports_soccer,
                    message: 'Sem jogos agendados.',
                  )
                else if (visibleDays.isEmpty)
                  EmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    message: _getEmptyMessage(),
                    isSmall: true,
                    onAction: _hasActiveFilter
                        ? () => setState(() {
                            _filterMode = FilterMode.all;
                            _selectedDay = null;
                          })
                        : null,
                    actionLabel: 'LIMPAR FILTROS',
                  )
                else
                  ...visibleDays.map(
                    (day) =>
                        _buildDaySection(day, filtered[day]!, presencas, uid),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  String _getEmptyMessage() {
    if (_filterMode == FilterMode.mine) {
      return 'Não criaste nenhum game.';
    }
    if (_filterMode == FilterMode.attending) {
      return 'Não tens games confirmados.';
    }
    return 'Nenhum game encontrado.';
  }

  Widget _buildDaySection(
    DateTime day,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> items,
    AttendanceService presencas,
    String? uid,
  ) {
    items.sort((a, b) {
      final da = (a.data()['date'] as Timestamp).toDate();
      final db = (b.data()['date'] as Timestamp).toDate();
      return da.compareTo(db);
    });

    final dayStr = _formatDayTitle(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8, top: 4),
          child: Text(
            dayStr.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white30,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items.map(
          (doc) => GameCard(doc: doc, presencas: presencas, uid: uid),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _formatDayTitle(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (day == today) return 'Hoje';
    if (day == tomorrow) return 'Amanhã';

    // Fallback locale date
    final months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    final weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return '${weekdays[day.weekday - 1]}, ${day.day} ${months[day.month - 1]}';
  }
}

class _FilterButton extends StatelessWidget {
  final bool hasActiveFilter;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _FilterButton({
    required this.hasActiveFilter,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: hasActiveFilter
              ? cs.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasActiveFilter
                ? cs.primary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
            width: hasActiveFilter ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: hasActiveFilter ? cs.primary : Colors.white38,
              ),
            ),
            if (hasActiveFilter)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
