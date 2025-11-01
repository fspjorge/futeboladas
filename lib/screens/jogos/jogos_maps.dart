import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/weather_service.dart';

class JogosMapa extends StatefulWidget {
  const JogosMapa({super.key});

  @override
  State<JogosMapa> createState() => _JogosMapaState();
}

class _JogosMapaState extends State<JogosMapa> {
  final Completer<GoogleMapController> _controller = Completer();
  final WeatherService _weatherService = WeatherService();
  final Set<Marker> _marcadores = {};

  static const CameraPosition _inicio = CameraPosition(
    target: LatLng(38.7169, -9.1399), // Lisboa
    zoom: 7,
  );

  @override
  void initState() {
    super.initState();
    _carregarJogos();
  }

  Future<void> _carregarJogos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('jogos')
        .where('ativo', isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final local = data['local'] as String? ?? 'Local desconhecido';
      final dataJogo = (data['data'] as Timestamp?)?.toDate();
      final lat = (data['lat'] as num?)?.toDouble();
      final lon = (data['lon'] as num?)?.toDouble();

      try {
        double useLat;
        double useLon;
        if (lat != null && lon != null) {
          useLat = lat;
          useLon = lon;
        } else {
          final posicoes = await locationFromAddress('$local, Portugal');
          if (posicoes.isEmpty) continue;
          final pos = posicoes.first;
          useLat = pos.latitude;
          useLon = pos.longitude;
        }

        final tempo = await _weatherService.getWeather(useLat, useLon);
        String descricao = '';
        if (dataJogo != null && descricao.isEmpty) {
          final ft = await _weatherService.getForecastAt(useLat, useLon, dataJogo);
          if (ft != null) {
            final desc = (ft['desc'] as String?) ?? '';
            final temp = ft['temp'];
            final dn = ft['diaNoite'];
            descricao = '${desc.isNotEmpty ? '${desc[0].toUpperCase()}${desc.substring(1)}' : ''} â $tempÂºC  ';
          }
        }
        if (tempo != null && descricao.isEmpty) {
          final desc = tempo['weather'][0]['description'];
          final temp = tempo['main']['temp'].round();
          descricao = '${desc[0].toUpperCase()}${desc.substring(1)} â $tempºC';
        }

        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(useLat, useLon),
          infoWindow: InfoWindow(
            title: local,
            snippet: dataJogo != null
                ? '${dataJogo.day.toString().padLeft(2, '0')}/${dataJogo.month.toString().padLeft(2, '0')} ${dataJogo.hour.toString().padLeft(2, '0')}:${dataJogo.minute.toString().padLeft(2, '0')} â $descricao'
                : descricao,
          ),
        );

        setState(() {
          _marcadores.add(marker);
        });
      } catch (e) {
        debugPrint('Erro ao processar local $local: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Jogos'),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _inicio,
        markers: _marcadores,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }
}


