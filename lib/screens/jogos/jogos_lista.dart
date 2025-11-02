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
        ;
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sports_soccer, color: cs.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              local,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                            backgroundColor: cs.primaryContainer,
                            labelStyle: TextStyle(color: cs.onPrimaryContainer),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatoData.format(date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: cs.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Organizador: $createdByName',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
                                  style: Theme.of(context).textTheme.bodyMedium,
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
                                                  SnackBar(content: Text('Erro ao atualizar presenÃ§a: $e')),
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
                              'A obter previsÃ£o do tempo...',
                              style: TextStyle(fontSize: 12),
                            );
                          }
                          if (snap.hasError || !snap.hasData || snap.data == null) {
                            return const SizedBox();
                          }
                          final info = snap.data!;
                          final descricao = info['desc'] as String;
                          final temp = info['temp'];
                          return Text(
                            '${descricao.isNotEmpty ? '${descricao[0].toUpperCase()}${descricao.substring(1)}' : ''} - $tempÂ°C',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
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
        final docs = snapshot.data!.docs;
        final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grupos = {};
        for (final d in docs) {
          final dt = (d.data()['data'] as Timestamp).toDate();
          final key = DateFormat('yyyy-MM-dd').format(dt);
          grupos.putIfAbsent(key, () => []).add(d);
        }
        final orderedKeys = grupos.keys.toList()..sort((a,b)=>a.compareTo(b));
        final cs = Theme.of(context).colorScheme;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orderedKeys.length,
          itemBuilder: (context, i) {
            final key = orderedKeys[i];
            final dayDate = DateFormat('yyyy-MM-dd').parse(key);
            final dayName = DateFormat.E('pt_PT').format(dayDate).toUpperCase();
            final dayNum = DateFormat.d('pt_PT').format(dayDate);
            final items = grupos[key]!;
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
                      children: items.map((doc){
                        final data = doc.data();
                        final local = data['local'] as String? ?? 'Local desconhecido';
                        final jogadores = (data['jogadores'] as num?)?.toInt() ?? 0;
                        final date = (data['data'] as Timestamp).toDate();
                        final jogoId = doc.id;
                        final createdByName = data['createdByName'] as String? ?? 'Desconhecido';
                        final createdBy = data['createdBy'] as String?;
                        final hora = DateFormat('HH:mm').format(date);
                        return Padding(
                          padding: const EdgeInsets.only(right: 12, bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: ()=> Navigator.of(context).push(MaterialPageRoute(builder: (_)=> JogoDetalhe(jogoId: jogoId))),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.08), blurRadius: 8, offset: Offset(0,4))],
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
                                          Text(local, maxLines: 2, overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          Row(children:[
                                            Icon(Icons.person_outline, size: 16, color: cs.onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Expanded(child: Text('Organizador: '+createdByName,
                                              maxLines: 1, overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)))
                                          ]),
                                          const SizedBox(height: 6),
                                          StreamBuilder<int>(
                                            stream: PresencaService().countConfirmados(jogoId),
                                            builder: (context, countSnap){
                                              final confirmados = countSnap.data ?? 0;
                                              return Row(children:[
                                                Expanded(child: Text('Confirmados: '+confirmados.toString()+'/'+(jogadores>0? jogadores.toString(): '-'),
                                                  style: Theme.of(context).textTheme.bodyMedium)),
                                                if (uid != null)
                                                  StreamBuilder<bool>(
                                                    stream: PresencaService().minhaPresenca(jogoId),
                                                    builder: (context, meSnap){
                                                      final vou = meSnap.data ?? false;
                                                      final lotado = !vou && jogadores>0 && confirmados>=jogadores;
                                                      return OutlinedButton(
                                                        onPressed: lotado? null: () async {
                                                          try{
                                                            if(!vou && jogadores>0 && confirmados>=jogadores){
                                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jogo lotado.')));
                                                              return;
                                                            }
                                                            await PresencaService().marcarPresenca(jogoId, !vou);
                                                          }catch(e){
                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar presença: '+e.toString())));
                                                          }
                                                        },
                                                        child: Text(vou? 'Desmarcar':'Vou'),
                                                      );
                                                    }
                                                  )
                                              ]);
                                            }
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            );
          },
        );

