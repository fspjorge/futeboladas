import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../../services/weather_service.dart';

class JogosLista extends StatelessWidget {
  const JogosLista({super.key});

  Future<Map<String, dynamic>?> _buscarTempoPorLocal(String local, DateTime quando) async {
    try {
      final resultados = await locationFromAddress('$local, Portugal');
      if (resultados.isEmpty) return null;

      final loc = resultados.first;
      // Tenta previsão na hora agendada; se não houver, faz fallback para meteo atual
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

      final diaNoite = (horaLocal.isAfter(nascer) && horaLocal.isBefore(por)) ? '🌞 Dia' : '🌙 Noite';

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

      final diaNoite = (horaLocal.isAfter(nascer) && horaLocal.isBefore(por)) ? '🌞 Dia' : '🌙 Noite';

      return {'desc': desc, 'temp': temp, 'diaNoite': diaNoite};
    } catch (e) {
      debugPrint('Erro ao obter tempo (coords): $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatoData = DateFormat('dd/MM/yyyy HH:mm');

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
            final data = jogos[index].data();
            final local = data['local'] as String? ?? 'Local desconhecido';
            final jogadores = (data['jogadores'] as num?)?.toInt() ?? 0;
            final date = (data['data'] as Timestamp).toDate();
            final lat = (data['lat'] as num?)?.toDouble();
            final lon = (data['lon'] as num?)?.toDouble();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          ),
                        ),
                        Chip(
                          label: Text('$jogadores'),
                          backgroundColor: Colors.green.shade100,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatoData.format(date),
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
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
                        if (snap.hasError) {
                          return const SizedBox();
                        }
                        if (!snap.hasData || snap.data == null) {
                          return const SizedBox();
                        }
                        final info = snap.data!;
                        final descricao = info['desc'] as String;
                        final temp = info['temp'];
                        // Mostramos apenas descrição e temperatura (sem Dia/Noite)
                        return Text(
                          '${descricao[0].toUpperCase()}${descricao.substring(1)} — $temp°C',
                          style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
