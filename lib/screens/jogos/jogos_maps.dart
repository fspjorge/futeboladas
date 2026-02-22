import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/weather_service.dart';

class JogosMapa extends StatefulWidget {
  const JogosMapa({super.key});

  @override
  State<JogosMapa> createState() => _JogosMapaState();
}

class _JogosMapaState extends State<JogosMapa> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _marcadores = {};
  bool _loading = true;

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
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('jogos')
          .where('ativo', isEqualTo: true)
          .get();

      final List<Marker> newMarkers = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final local = data['local'] as String? ?? 'Local desconhecido';
        final dataJogo = (data['data'] as Timestamp?)?.toDate();
        final lat = (data['lat'] as num?)?.toDouble();
        final lon = (data['lon'] as num?)?.toDouble();

        try {
          double? useLat = lat;
          double? useLon = lon;

          if (useLat == null || useLon == null) {
            final posicoes = await locationFromAddress('$local, Portugal');
            if (posicoes.isNotEmpty) {
              useLat = posicoes.first.latitude;
              useLon = posicoes.first.longitude;
            }
          }

          if (useLat != null && useLon != null) {
            String weatherInfo = '';
            if (dataJogo != null) {
              final forecast = await WeatherService().getForecastAt(
                useLat,
                useLon,
                dataJogo,
              );
              if (forecast != null) {
                final desc = (forecast['desc'] as String?) ?? '';
                final temp = forecast['temp'];
                weatherInfo =
                    ' | ${desc.isNotEmpty ? '${desc[0].toUpperCase()}${desc.substring(1)}' : ''} $temp°C';
              }
            }

            newMarkers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(useLat, useLon),
                infoWindow: InfoWindow(
                  title: local,
                  snippet: dataJogo != null
                      ? '${dataJogo.day}/${dataJogo.month} ${dataJogo.hour}:${dataJogo.minute.toString().padLeft(2, '0')}$weatherInfo'
                      : weatherInfo,
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint('Erro ao processar local $local: $e');
        }
      }

      if (mounted) {
        setState(() {
          _marcadores.addAll(newMarkers);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Mapa de Partidas',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _inicio,
            markers: _marcadores,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          if (_loading)
            Container(
              color: const Color(0xFF0F172A).withOpacity(0.8),
              child: const Center(child: CircularProgressIndicator()),
            ),
          // Gradient overlay for better text readability at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F172A), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
