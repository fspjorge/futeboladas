import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'jogo_mapa_detalhe.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<LatLng?> _obterLatLng(String local, Map<String, dynamic> data) async {
    final lat = (data['lat'] as num?)?.toDouble();
    final lon = (data['lon'] as num?)?.toDouble();
    if (lat != null && lon != null) {
      return LatLng(lat, lon);
    }
    try {
      final res = await locationFromAddress('$local, Portugal');
      if (res.isEmpty) return null;
      return LatLng(res.first.latitude, res.first.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _abrirNoGoogleMaps(LatLng pos, String label) async {
    final q = Uri.encodeComponent(label);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}&query_place_id=$q');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // fallback para geo: (pode não funcionar em todos os dispositivos)
      final geo = Uri.parse('geo:${pos.latitude},${pos.longitude}?q=${pos.latitude},${pos.longitude}($q)');
      await launchUrl(geo, mode: LaunchMode.externalApplication);
    }
  }

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
                          Icon(Icons.place_outlined, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              local,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
              // Localização + mapa
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Localização',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        local,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<LatLng?>(
                        future: _obterLatLng(local, data),
                        builder: (context, posSnap) {
                          if (posSnap.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 220,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final pos = posSnap.data;
                          if (pos == null) {
                            return const Text('Não foi possível localizar o endereço no mapa.');
                          }
                          final width = 640; // Static Maps free tier máx.
                          final height = 320;
                          const key = String.fromEnvironment(
                            'PLACES_API_KEY',
                            defaultValue: 'AIzaSyAPRZImkhwXKE0lqBhYAUvlBXKLN-UbnYk',
                          );
                          final url = Uri.https(
                            'maps.googleapis.com',
                            '/maps/api/staticmap',
                            {
                              'center': '${pos.latitude},${pos.longitude}',
                              'zoom': '15',
                              'size': '${width}x$height',
                              'scale': '2',
                              'maptype': 'roadmap',
                              'markers': 'color:green|${pos.latitude},${pos.longitude}',
                              'key': key,
                            },
                          ).toString();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  height: 220,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const SizedBox(
                                    height: 220,
                                    child: Center(child: Text('Falha ao carregar mapa.')),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _abrirNoGoogleMaps(pos, local),
                                    icon: const Icon(Icons.directions),
                                    label: const Text('Abrir no Google Maps'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => JogoMapaDetalhe(pos: pos, titulo: local),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.map_outlined),
                                    label: const Text('Mapa interativo'),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
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
                        Text('Criado por: ${data['createdByName'] ?? 'Desconhecido'}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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

