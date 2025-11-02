import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/weather_service.dart';
import 'jogo_detalhe.dart';
import '../../services/presenca_service.dart';
import 'jogo_editar.dart';

class JogosLista extends StatelessWidget {
  const JogosLista({super.key});

  Future<Map<String, dynamic>?> _buscarTempoPorLocal(String local, DateTime quando) async {
    try {
      final resultados = await locationFromAddress('$local, Portugal');
      if (resultados.isEmpty) return null;

      final loc = resultados.first;
      final dadosForecast = await WeatherService().getForecastAt(loc.latitude, loc.longitude, quando);
      if (dadosForecast != null) return dadosForecast;

      final dados = await WeatherService().getWeather(loc.latitude, loc.longitude);
      if (dados == null) return null;

      final desc = dados['weather'][0]['description'] as String;
      final temp = (dados['main']['temp'] as num).round();
      final horaLocal = DateTime.fromMillisecondsSinceEpoch(
        (dados['dt'] as num).toInt() * 1000,
        isUtc: true,
      ).add(Duration(seconds: (dados['timezone'] as num?)?.toInt() ?? 0));

      final nascer = DateTime.fromMillisecondsSinceEpoch(
        (dados['sys']['sunrise'] as num).toInt() * 1000,
        isUtc: true,
      ).add(Duration(seconds: (dados['timezone'] as num?)?.toInt() ?? 0));

      final por = DateTime.fromMillisecondsSinceEpoch(
        (dados['sys']['sunset'] as num).toInt() * 1000,
        isUtc: true,
      ).add(Duration(seconds: (dados['timezone'] as num?)?.toInt() ?? 0));

      final diaNoite = (horaLocal.isAfter(nascer) && horaLocal.isBefore(por)) ? 'Dia' : 'Noite';

      return {'desc': desc, 'temp': temp, 'diaNoite': diaNoite};
    } catch (e) {
      debugPrint('Erro ao obter tempo (local): $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _buscarTempoPorCoords(double lat, double lon, DateTime quando) async {
    try {
      final dadosForecast = await WeatherService().getForecastAt(lat, lon, quando);
      if (dadosForecast != null) return dadosForecast;

      final dados = await WeatherService().getWeather(lat, lon);
      if (dados == null) return null;

      final desc = dados['weather'][0]['description'] as String;
      final temp = (dados['main']['temp'] as num).round();
      final horaLocal = DateTime.fromMillisecondsSinceEpoch(
        (dados['dt'] as num).toInt() * 1000,
        isUtc: true,
      ).add(Duration(seconds: (dados['timezone'] as num?)?.toInt() ?? 0));

      final nascer = DateTime.fromMillisecondsSinceEpoch(
        (dados['sys']['sunrise'] as num).toInt() * 1000,
        isUtc: true,
      ).add(Duration(seconds: (dados['timezone'] as num?)?.toInt() ?? 0));

      final por = DateTime.fromMillisecondsSinceEpoch(
        (dados['sys']['sunset'] as num).toInt() * 1000,
        isUtc: true,
      ).add(Duration(seconds: (dados['timezone'] as num?)?.toInt() ?? 0));

      final diaNoite = (horaLocal.isAfter(nascer) && horaLocal.isBefore(por)) ? 'Dia' : 'Noite';

      return {'desc': desc, 'temp': temp, 'diaNoite': diaNoite};
    } catch (e) {
      debugPrint('Erro ao obter tempo (coords): $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatoData = DateFormat('dd/MM/yyyy HH:mm');
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

        final jogos = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: jogos.length,
          itemBuilder: (context, index) {
            final doc = jogos[index];
            final data = doc.data();
            final local = data['local'] as String? ?? 'Local desconhecido';
            final jogadores = (data['jogadores'] as num?)?.toInt() ?? 0;
            final date = (data['data'] as Timestamp).toDate();
            final lat = (data['lat'] as num?)?.toDouble();
            final lon = (data['lon'] as num?)?.toDouble();
            final jogoId = doc.id;
            final createdByName = data['createdByName'] as String? ?? 'Desconhecido';
            final createdBy = data['createdBy'] as String?;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => JogoDetalhe(jogoId: jogoId),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sports_soccer, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              local,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (FirebaseAuth.instance.currentUser?.uid == createdBy)
                            IconButton(
                              tooltip: 'Editar jogo',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => JogoEditar(jogoId: jogoId)),
                                );
                              },
                            ),
                          Chip(
                            label: Text('$jogadores'),
                            backgroundColor: Colors.green.shade100,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatoData.format(date),
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Organizador: $createdByName',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                      const SizedBox(height: 6),
                      FutureBuilder<Map<String, dynamic>?>(
                        future: (lat != null && lon != null)
                            ? _buscarTempoPorCoords(lat, lon, date)
                            : _buscarTempoPorLocal(local, date),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Text(
                              'A obter previsão do tempo...',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            );
                          }
                          if (snap.hasError || !snap.hasData || snap.data == null) {
                            return const SizedBox();
                          }
                          final info = snap.data!;
                          final descricao = info['desc'] as String;
                          final temp = info['temp'];
                          return Text(
                            '${descricao.isNotEmpty ? '${descricao[0].toUpperCase()}${descricao.substring(1)}' : ''} - $temp°C',
                            style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
