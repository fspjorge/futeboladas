import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'jogo_detalhe.dart';
import 'confirmacao_page.dart';
import '../../services/presenca_service.dart';
import '../../services/weather_service.dart'; // ← NOVO

class JogosLista extends StatefulWidget {
  final String searchQuery;
  const JogosLista({super.key, this.searchQuery = ''});

  @override
  State<JogosLista> createState() => _JogosListaState();
}

enum FilterMode { todos, meus, participo, gratuitos }

class _JogosListaState extends State<JogosLista> {
  FilterMode _filterMode = FilterMode.todos;
  Set<String> _jogosOndeVou = {};
  bool _loadingVou = false;
  DateTime? _selectedDay;

  bool get _hasActiveFilter =>
      _filterMode != FilterMode.todos || _selectedDay != null;

  String _formatarPreco(num? preco) {
    if (preco == null || preco <= 0) return 'Grátis';
    return '€${preco.toStringAsFixed(2)}';
  }

  Future<void> _loadJogosOndeVou() async {
    if (!mounted) return;
    setState(() => _loadingVou = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final snap = await FirebaseFirestore.instance
          .collectionGroup('presencas')
          .where('uid', isEqualTo: uid)
          .where('vai', isEqualTo: true)
          .get();

      if (!mounted) return;
      setState(() {
        _jogosOndeVou = snap.docs
            .map((d) => d.reference.parent.parent!.id)
            .toSet();
      });
    } catch (e) {
      debugPrint('Erro: $e');
    } finally {
      if (mounted) setState(() => _loadingVou = false);
    }
  }

  void _openFilterSheet(BuildContext context, ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'FILTROS',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white38,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: [
                        _sheetChip(
                          'Todos',
                          Icons.grid_view_rounded,
                          _filterMode == FilterMode.todos,
                          cs,
                          () {
                            setSheetState(() => _filterMode = FilterMode.todos);
                            setState(() => _filterMode = FilterMode.todos);
                          },
                        ),
                        _sheetChip(
                          'Meus',
                          Icons.person_outline_rounded,
                          _filterMode == FilterMode.meus,
                          cs,
                          () {
                            final newMode = _filterMode == FilterMode.meus
                                ? FilterMode.todos
                                : FilterMode.meus;
                            setSheetState(() => _filterMode = newMode);
                            setState(() => _filterMode = newMode);
                          },
                        ),
                        _sheetChip(
                          'Confirmados',
                          Icons.check_circle_outline_rounded,
                          _filterMode == FilterMode.participo,
                          cs,
                          () {
                            final newMode = _filterMode == FilterMode.participo
                                ? FilterMode.todos
                                : FilterMode.participo;
                            setSheetState(() => _filterMode = newMode);
                            setState(() => _filterMode = newMode);
                            if (newMode == FilterMode.participo) {
                              _loadJogosOndeVou();
                            }
                          },
                        ),
                        _sheetChip(
                          'Gratuitos',
                          Icons.money_off_csred_outlined,
                          _filterMode == FilterMode.gratuitos,
                          cs,
                          () {
                            final newMode = _filterMode == FilterMode.gratuitos
                                ? FilterMode.todos
                                : FilterMode.gratuitos;
                            setSheetState(() => _filterMode = newMode);
                            setState(() => _filterMode = newMode);
                          },
                        ),
                      ],
                    ),
                    if (_hasActiveFilter) ...[
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: () {
                          setSheetState(() {});
                          setState(() {
                            _filterMode = FilterMode.todos;
                            _selectedDay = null;
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close_rounded, size: 14),
                        label: Text(
                          'Limpar filtros',
                          style: GoogleFonts.outfit(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white38,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sheetChip(
    String label,
    IconData icon,
    bool selected,
    ColorScheme cs,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? cs.primary.withOpacity(0.6)
                : Colors.white.withOpacity(0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? cs.primary : Colors.white38),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                color: selected ? cs.primary : Colors.white60,
              ),
            ),
          ],
        ),
      ),
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

      // Filtro de pesquisa
      if (widget.searchQuery.isNotEmpty) {
        final q = widget.searchQuery.toLowerCase();
        final titulo = (data['titulo'] as String? ?? '').toLowerCase();
        final local = (data['local'] as String? ?? '').toLowerCase();
        if (!titulo.contains(q) && !local.contains(q)) continue;
      }

      if (uid != null) {
        if (_filterMode == FilterMode.meus && data['createdBy'] != uid)
          continue;
        if (_filterMode == FilterMode.participo &&
            !_jogosOndeVou.contains(d.id))
          continue;
        if (_filterMode == FilterMode.gratuitos) {
          final preco = data['preco'] as num? ?? 0;
          if (preco > 0) continue;
        }
      }

      if (_selectedDay != null) {
        final dt = (data['data'] as Timestamp).toDate();
        final day = DateTime(dt.year, dt.month, dt.day);
        if (day != _selectedDay) continue;
      }

      final dt = (data['data'] as Timestamp).toDate();
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
      final dt = (d.data()['data'] as Timestamp).toDate();
      days.add(DateTime(dt.year, dt.month, dt.day));
    }
    return days.toList()..sort();
  }

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
        if (snapshot.connectionState == ConnectionState.waiting ||
            (_loadingVou && _filterMode == FilterMode.participo)) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) return _buildErrorState();

        final docs = snapshot.data?.docs ?? [];
        final allDays = _getAllDays(docs);
        final filtered = _processGames(docs, uid);
        final visibleDays = filtered.keys.toList()..sort();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header com seletor de dias + botão filtro
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildDaySelector(allDays, cs)),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: _buildFilterButton(cs, context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (docs.isEmpty)
              _buildEmptyState(
                icon: Icons.sports_soccer,
                message: 'Sem jogos agendados.',
                cs: cs,
              )
            else if (visibleDays.isEmpty)
              _buildEmptyState(
                icon: Icons.filter_alt_off_outlined,
                message: 'Nenhum jogo encontrado.',
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

  Widget _buildFilterButton(ColorScheme cs, BuildContext context) {
    return GestureDetector(
      onTap: () => _openFilterSheet(context, cs),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _hasActiveFilter
              ? cs.primary.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hasActiveFilter
                ? cs.primary.withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
            width: _hasActiveFilter ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: _hasActiveFilter ? cs.primary : Colors.white38,
              ),
            ),
            if (_hasActiveFilter)
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

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(height: 12),
          Text(
            'A carregar...',
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
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
          const SizedBox(height: 12),
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
    String msg = message;
    if (isSmall) {
      if (_filterMode == FilterMode.meus)
        msg = 'Não criaste nenhum jogo.';
      else if (_filterMode == FilterMode.participo)
        msg = 'Não tens jogos confirmados.';
    }
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isSmall ? 32 : 80),
        child: Column(
          children: [
            Icon(icon, size: isSmall ? 36 : 56, color: Colors.white10),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 15),
            ),
            if (isSmall && _hasActiveFilter)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton(
                  onPressed: () => setState(() {
                    _filterMode = FilterMode.todos;
                    _selectedDay = null;
                  }),
                  child: Text(
                    'LIMPAR FILTROS',
                    style: TextStyle(color: cs.primary, fontSize: 12),
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

    final monthDisplay = _selectedDay != null
        ? DateFormat('MMMM yyyy', 'pt_PT').format(_selectedDay!).toUpperCase()
        : DateFormat('MMMM yyyy', 'pt_PT').format(allDays.first).toUpperCase();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            monthDisplay,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: cs.primary.withOpacity(0.5),
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(
          height: 62,
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
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () =>
                      setState(() => _selectedDay = selected ? null : day),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary
                          : isToday
                          ? cs.primary.withOpacity(0.1)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? cs.primary
                            : isToday
                            ? cs.primary.withOpacity(0.4)
                            : Colors.white.withOpacity(0.07),
                        width: isToday && !selected ? 1.5 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: cs.primary.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isToday && !selected)
                          Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          DateFormat.d('pt_PT').format(day),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? const Color(0xFF0F172A)
                                : isToday
                                ? cs.primary
                                : Colors.white,
                          ),
                        ),
                        Text(
                          DateFormat.E(
                            'pt_PT',
                          ).format(day).toUpperCase().substring(0, 3),
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: selected
                                ? const Color(0xFF0F172A).withOpacity(0.6)
                                : isToday
                                ? cs.primary.withOpacity(0.7)
                                : Colors.white30,
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

    final dayStr = DateFormat("EEE, d 'de' MMM", 'pt_PT').format(day);

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
        ...items.map((doc) => _buildGameCard(doc, presencas, uid, cs)),
        const SizedBox(height: 8),
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
    final preco = data['preco'] as num? ?? 0;
    final date = (data['data'] as Timestamp).toDate();
    final jogoId = doc.id;
    final hora = DateFormat('HH:mm').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => JogoDetalhe(jogoId: jogoId)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      hora,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withOpacity(0.08),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: presencas.countConfirmados(jogoId),
                      builder: (context, countSnap) {
                        final confirmados = countSnap.data ?? 0;
                        final bool hasLimit = maxJogadores > 0;
                        final bool isFull =
                            hasLimit && confirmados >= maxJogadores;
                        final dotColor = isFull ? cs.error : cs.primary;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              local,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (hasLimit) ...[
                                  ...List.generate(
                                    maxJogadores.clamp(0, 8),
                                    (i) => Container(
                                      margin: const EdgeInsets.only(right: 2),
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: i < confirmados
                                            ? dotColor
                                            : Colors.white.withOpacity(0.12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$confirmados/$maxJogadores',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isFull ? cs.error : Colors.white30,
                                    ),
                                  ),
                                ] else
                                  Text(
                                    '$confirmados jogadores',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: Colors.white30,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                // Preço ao lado do número de jogadores
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: preco > 0
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _formatarPreco(preco),
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: preco > 0
                                          ? Colors.green
                                          : Colors.blue,
                                    ),
                                  ),
                                ),
                                if (data['lat'] != null &&
                                    data['lon'] != null &&
                                    data['data'] != null) ...[
                                  const SizedBox(width: 8),
                                  FutureBuilder<Map<String, dynamic>?>(
                                    future: WeatherService().getForecastAt(
                                      (data['lat'] as num).toDouble(),
                                      (data['lon'] as num).toDouble(),
                                      (data['data'] as Timestamp).toDate(),
                                    ),
                                    builder: (context, weatherSnap) {
                                      if (!weatherSnap.hasData ||
                                          weatherSnap.data == null) {
                                        return const SizedBox.shrink();
                                      }
                                      final w = weatherSnap.data!;
                                      return Row(
                                        children: [
                                          Icon(
                                            w['diaNoite'] == 'Noite'
                                                ? Icons.nightlight_round
                                                : Icons.wb_sunny_rounded,
                                            size: 10,
                                            color: Colors.amber.withOpacity(
                                              0.6,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${w['temp']}°C',
                                            style: GoogleFonts.outfit(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white30,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (uid != null)
                    StreamBuilder<int>(
                      stream: presencas.countConfirmados(jogoId),
                      builder: (context, countSnap) {
                        final confirmados = countSnap.data ?? 0;
                        final bool isFull =
                            maxJogadores > 0 && confirmados >= maxJogadores;
                        return StreamBuilder<bool>(
                          stream: presencas.minhaPresenca(jogoId),
                          builder: (context, meSnap) {
                            final isGoing = meSnap.data ?? false;
                            return _buildJoinButton(isGoing, isFull, () async {
                              try {
                                if (!isGoing && isFull) {
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                                if (_filterMode == FilterMode.participo)
                                  _loadJogosOndeVou();
                                if (!isGoing && mounted) {
                                  String? weatherStr;
                                  final lat = (data['lat'] as num?)?.toDouble();
                                  final lon = (data['lon'] as num?)?.toDouble();
                                  if (lat != null &&
                                      lon != null &&
                                      date != null) {
                                    final w = await WeatherService()
                                        .getForecastAt(lat, lon, date);
                                    if (w != null) {
                                      final desc = w['desc'] as String? ?? '';
                                      final capitalizedDesc = desc.isNotEmpty
                                          ? '${desc[0].toUpperCase()}${desc.substring(1)}'
                                          : '';
                                      weatherStr =
                                          '$capitalizedDesc, ${w['temp']}°C';
                                    }
                                  }

                                  if (mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ConfirmacaoJogoPage(
                                          titulo:
                                              data['titulo'] as String? ??
                                              local,
                                          data: date,
                                          local: local,
                                          preco: preco.toDouble(),
                                          weather: weatherStr,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erro: $e')),
                                );
                              }
                            }, cs);
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: Colors.white24),
          foregroundColor: Colors.white60,
          textStyle: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: const Text('SAIR'),
      );
    }

    return ElevatedButton(
      onPressed: isFull ? null : onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: isFull ? Colors.white10 : cs.primary,
        foregroundColor: isFull ? Colors.white24 : const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      child: Text(
        isFull ? 'LOTADO' : 'IR',
        style: GoogleFonts.outfit(
          fontSize: isFull ? 10 : 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
