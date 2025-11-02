import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'jogo_detalhe.dart';
import '../../services/presenca_service.dart';

class JogosLista extends StatelessWidget {
  const JogosLista({super.key});

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
        final Map<DateTime, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grupos = {};
        for (final d in docs) {
          final dt = (d.data()['data'] as Timestamp).toDate();
          final day = DateTime(dt.year, dt.month, dt.day);
          grupos.putIfAbsent(day, () => []).add(d);
        }
        final dias = grupos.keys.toList()..sort();
        final cs = Theme.of(context).colorScheme;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dias.length,
          itemBuilder: (context, i) {
            final day = dias[i];
            final dayName = DateFormat.E('pt_PT').format(day).toUpperCase();
            final dayNum = DateFormat.d('pt_PT').format(day);
            final items = grupos[day]!..sort((a, b) {
              final da = (a.data()['data'] as Timestamp).toDate();
              final db = (b.data()['data'] as Timestamp).toDate();
              return da.compareTo(db);
            });

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
                      children: items!.map((doc) {
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
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4)),
                                ],
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
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        const SnackBar(content: Text('Jogo lotado.')),
                                                                      );
                                                                      return;
                                                                    }
                                                                    await presencas.marcarPresenca(jogoId, !vou);
                                                                  } catch (e) {
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      SnackBar(content: Text('Erro ao atualizar presença: $e')),
                                                                    );
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
          },
        );
      },
    );
  }
}

