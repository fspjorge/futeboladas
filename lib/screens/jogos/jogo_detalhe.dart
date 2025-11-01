import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/presenca_service.dart';
import 'jogo_editar.dart';

class JogoDetalhe extends StatefulWidget {
  final String jogoId;
  const JogoDetalhe({super.key, required this.jogoId});

  @override
  State<JogoDetalhe> createState() => _JogoDetalheState();
}

class _JogoDetalheState extends State<JogoDetalhe> {
  final _contactosCtrl = TextEditingController();
  final _historicoCtrl = TextEditingController();
  bool _adminLoaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _contactosCtrl.dispose();
    _historicoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final presencas = PresencaService();
    final jogoRef = FirebaseFirestore.instance.collection('jogos').doc(widget.jogoId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do Jogo'),
        actions: [
          if (uid != null)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: jogoRef.snapshots(),
              builder: (context, s) {
                if (!s.hasData) return const SizedBox.shrink();
                final isOwner = (s.data!.data()?['createdBy'] == uid);
                if (!isOwner) return const SizedBox.shrink();
                return IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final ok = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => JogoEditar(jogoId: widget.jogoId)),
                    );
                    if (ok == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Jogo atualizado.')),
                      );
                    }
                  },
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: jogoRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Jogo não encontrado.'));
          }
          final data = snap.data!.data()!;
          final local = data['local'] as String? ?? 'Local desconhecido';
          final date = (data['data'] as Timestamp?)?.toDate();
          final maxJogadores = (data['jogadores'] as num?)?.toInt();
          final createdBy = data['createdBy'] as String?;
          final createdByName = data['createdByName'] as String? ?? 'Desconhecido';
          final isOwner = uid != null && createdBy == uid;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Público: local, data, organizador, confirmados
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              local,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule_outlined, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            date != null
                                ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                                : 'Sem data',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 18),
                          const SizedBox(width: 6),
                          Text('Organizador: $createdByName'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<int>(
                        stream: presencas.countConfirmados(widget.jogoId),
                        builder: (context, countSnap) {
                          final confirmados = countSnap.data ?? 0;
                          return Row(
                            children: [
                              const Icon(Icons.people_outline, size: 18),
                              const SizedBox(width: 6),
                              Text('Confirmados: $confirmados/${maxJogadores ?? '-'}'),
                            ],
                          );
                        },
                      ),
                      if (isOwner)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar jogo'),
                            onPressed: () async {
                              final ok = await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => JogoEditar(jogoId: widget.jogoId)),
                              );
                              if (ok == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Jogo atualizado.')),
                                );
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Autenticados: lista de jogadores confirmados
              if (uid != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jogadores confirmados', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: jogoRef.collection('presencas').where('vai', isEqualTo: true).snapshots(),
                          builder: (context, psnap) {
                            if (psnap.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final docs = psnap.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return const Text('Ainda sem confirmações.');
                            }
                            return Column(
                              children: docs.map((d) {
                                final n = d.data()['name'] as String? ?? 'Jogador';
                                final p = d.data()['photo'] as String?;
                                final isOrganizer = d.id == (createdBy ?? '');
                                final title = isOrganizer ? '$n (organizador)' : n;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundImage: p != null ? NetworkImage(p) : null,
                                    child: p == null ? const Icon(Icons.person_outline) : null,
                                  ),
                                  title: Text(title),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Botão Vou/Desmarcar
              if (uid != null)
                StreamBuilder<bool>(
                  stream: presencas.minhaPresenca(widget.jogoId),
                  builder: (context, meSnap) {
                    final vou = meSnap.data ?? false;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await presencas.marcarPresenca(widget.jogoId, !vou);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao atualizar presença: $e')),
                            );
                          }
                        },
                        icon: Icon(vou ? Icons.event_busy : Icons.check_circle_outline),
                        label: Text(vou ? 'Desmarcar' : 'Vou'),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 12),

              // Organizador: área privada (admin/privado)
              if (isOwner)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Área do organizador', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            TextButton.icon(
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Editar jogo'),
                              onPressed: () async {
                                final ok = await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => JogoEditar(jogoId: widget.jogoId)),
                                );
                                if (ok == true && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Jogo atualizado.')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Criado por: ${data['createdByName'] ?? 'Desconhecido'}'),
                        const SizedBox(height: 12),
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: jogoRef.collection('admin').doc('privado').snapshots(),
                          builder: (context, asnap) {
                            final adata = asnap.data?.data() ?? {};
                            if (!_adminLoaded && adata.isNotEmpty) {
                              _contactosCtrl.text = (adata['contactos'] as String?) ?? '';
                              _historicoCtrl.text = (adata['historico'] as String?) ?? '';
                              _adminLoaded = true;
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _contactosCtrl,
                                  decoration: const InputDecoration(labelText: 'Contactos'),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _historicoCtrl,
                                  maxLines: 3,
                                  decoration: const InputDecoration(labelText: 'Histórico'),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _saving
                                        ? null
                                        : () async {
                                            setState(() => _saving = true);
                                            try {
                                              await jogoRef
                                                  .collection('admin')
                                                  .doc('privado')
                                                  .set(
                                                {
                                                  'contactos': _contactosCtrl.text.trim(),
                                                  'historico': _historicoCtrl.text.trim(),
                                                },
                                                SetOptions(merge: true),
                                              );
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Guardado.')),
                                              );
                                            } catch (e) {
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Erro: $e')),
                                              );
                                            } finally {
                                              if (mounted) setState(() => _saving = false);
                                            }
                                          },
                                    icon: _saving
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Icon(Icons.save_outlined),
                                    label: const Text('Guardar'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

