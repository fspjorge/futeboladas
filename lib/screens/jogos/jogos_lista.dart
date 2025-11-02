import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'jogo_detalhe.dart';
import 'confirmacao_page.dart';
import '../../services/presenca_service.dart';

class JogosLista extends StatefulWidget {
  const JogosLista({super.key});

  @override
  State<JogosLista> createState() => _JogosListaState();
}

class _JogosListaState extends State<JogosLista> {\n  DateTime? _selectedDay;\n  bool _onlyMine = false;\n  bool _onlyAvailable = false;
  DateTime? _selectedDay;
  bool _onlyMine = false;

  @override
  Widget build(BuildContext context) {
    final presencas = PresencaService();
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
          return const Center(child: Text('Erro a carregar jogos'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Sem jogos agendados.'));
        }

        final docs = snapshot.data!.docs;
        final Map<DateTime, List<QueryDocumentSnapshot<Map<String, dynamic>>>> groups = {};
        for (final d in docs) {
          final dt = (d.data()['data'] as Timestamp).toDate();
          final day = DateTime(dt.year, dt.month, dt.day);
          groups.putIfAbsent(day, () => []).add(d);
        }
        final allDays = groups.keys.toList()..sort();
        final cs = Theme.of(context).colorScheme;

        // filtros
        final Map<DateTime, List<QueryDocumentSnapshot<Map<String, dynamic>>>> filtered = {};
        for (final d in allDays) {
          final list = groups[d]!;
          final mine = _onlyMine && uid != null
              ? list.where((x) => (x.data()['createdBy'] as String?) == uid).toList()
              : list;
          if (mine.isNotEmpty) filtered[d] = mine;
        }
        final filteredDays = filtered.keys.toList()..sort();
        final visibleDays = _selectedDay == null
            ? filteredDays
            : filteredDays.where((d) => d.year == _selectedDay!.year && d.month == _selectedDay!.month && d.day == _selectedDay!.day).toList();

        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // barra de dias
            SizedBox(
              height: 74,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: allDays.length,
                itemBuilder: (context, i) {
                  final day = allDays[i];
                  final selected = _selectedDay != null && day.year == _selectedDay!.year && day.month == _selectedDay!.month && day.day == _selectedDay!.day;
                  final dayName = DateFormat.E('pt_PT').format(day).toUpperCase();
                  final dayNum = DateFormat.d('pt_PT').format(day);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedDay = selected ? null : day),
                      child: Container(
                        width: 56,
                        decoration: BoxDecoration(
                          color: selected ? cs.primary : cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(dayNum, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: selected ? cs.onPrimary : cs.onSurface)),
                            const SizedBox(height: 2),
                            Text(dayName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: selected ? cs.onPrimary : cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // filtros
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: !_onlyMine,
                    onSelected: (v) => setState(() => _onlyMine = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Meus'),
                    selected: _onlyMine,
                    onSelected: (v) => setState(() => _onlyMine = true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // timeline
            ...visibleDays.map((day) {
              final items = filtered[day]!;
              items.sort((a, b) {
                final da = (a.data()['data'] as Timestamp).toDate();
                final db = (b.data()['data'] as Timestamp).toDate();
                return da.compareTo(db);
              });
              final dayName = DateFormat.E('pt_PT').format(day).toUpperCase();
              final dayNum = DateFormat.d('pt_PT').format(day);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 64,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(dayName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(dayNum, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          Container(width: 2, height: 12, margin: const EdgeInsets.only(top: 6), color: cs.outlineVariant),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: items.map((doc) {
                          final data = doc.data();
                          final local = data['local'] as String? ?? 'Local desconhecido';
                          final jogadores = (data['jogadores'] as num?)?.toInt() ?? 0;
                          final date = (data['data'] as Timestamp).toDate();
                          final jogoId = doc.id;
                          final createdByName = data['createdByName'] as String? ?? 'Desconhecido';
                          final hora = DateFormat('HH:mm').format(date);

                          return Padding(
                            padding: const EdgeInsets.only(right: 12, bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => JogoDetalhe(jogoId: jogoId)),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))],
                                  border: Border(left: BorderSide(color: cs.primary, width: 6)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 56, child: Text(hora, style: Theme.of(context).textTheme.titleSmall)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              local,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.person_outline, size: 16, color: cs.onSurfaceVariant),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Organizador: $createdByName',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            StreamBuilder<int>(
                                              stream: presencas.countConfirmados(jogoId),
                                              builder: (context, countSnap) {
                                                final confirmados = countSnap.data ?? 0;
                                                return Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'Confirmados: $confirmados/${jogadores > 0 ? jogadores : '-'}',
                                                        style: Theme.of(context).textTheme.bodyMedium,
                                                      ),
                                                    ),
                                                  if (uid != null)
                                                      StreamBuilder<bool>(
                                                        stream: presencas.minhaPresenca(jogoId),
                                                        builder: (context, meSnap) {
                                                          final vou = meSnap.data ?? false;
                                                          final lotado = !vou && jogadores > 0 && confirmados >= jogadores;
                                                          return OutlinedButton(
                                                            onPressed: lotado
                                                                ? null
                                                                : () async {
                                                                    try {
                                                                      if (!vou && jogadores > 0 && confirmados >= jogadores) {
                                                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jogo lotado.')));
                                                                        return;
                                                                      }
                                                                      await presencas.marcarPresenca(jogoId, !vou);
                                                                      if (!vou) {
                                                                        // marcou presenÃ§a -> mostrar ecrÃ£ de confirmaÃ§Ã£o
                                                                        if (!context.mounted) return;
                                                                        Navigator.of(context).push(
                                                                          MaterialPageRoute(
                                                                            builder: (_) => ConfirmacaoJogoPage(
                                                                              titulo: local,
                                                                              data: date,
                                                                              local: local,
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }
                                                                    } catch (e) {
                                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar presenÃ§a: $e')));
                                                                    }
                                                                  },
                                                            child: Text(vou ? 'Desmarcar' : 'Vou'),
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
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}



