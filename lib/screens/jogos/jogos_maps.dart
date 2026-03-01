import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/presenca_service.dart';
import '../../services/weather_service.dart';
import 'jogo_detalhe.dart';
import 'confirmacao_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JogosMapa extends StatefulWidget {
  const JogosMapa({super.key});

  @override
  State<JogosMapa> createState() => _JogosMapaState();
}

class _JogosMapaState extends State<JogosMapa> with WidgetsBindingObserver {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _marcadores = {};
  final Map<String, Map<String, dynamic>> _jogosData = {};
  bool _loading = true;
  bool _hasLocationPermission = false;
  bool _mapInitialized = false;
  String? _errorMessage;
  final PresencaService _presencaService = PresencaService();

  static const CameraPosition _inicio = CameraPosition(
    target: LatLng(38.7169, -9.1399),
    zoom: 7,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      await _checkLocationPermission();
      await _carregarJogos();
      if (mounted) {
        setState(() {
          _mapInitialized = true;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao inicializar mapa: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        setState(() {
          _hasLocationPermission =
              requested == LocationPermission.always ||
              requested == LocationPermission.whileInUse;
        });
      } else {
        setState(() {
          _hasLocationPermission =
              permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse;
        });
      }
    } catch (e) {
      debugPrint('Erro ao verificar permissão de localização: $e');
      setState(() => _hasLocationPermission = false);
    }
  }

  Future<void> _goToUserLocation() async {
    if (!_hasLocationPermission) {
      _showSnackBar(
        'Permissão de localização necessária',
        color: Colors.orangeAccent,
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );

      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('Erro ao obter localização: $e');
    }
  }

  void _showSnackBar(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color ?? Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _togglePresenca(
    String jogoId,
    String local,
    DateTime? dataJogo,
  ) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _showSnackBar('Precisas de estar autenticado');
        return;
      }

      final isGoing = await _presencaService.minhaPresenca(jogoId).first;

      await _presencaService.marcarPresenca(jogoId, !isGoing);

      if (!isGoing && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConfirmacaoJogoPage(
              titulo: local,
              data: dataJogo ?? DateTime.now(),
              local: local,
            ),
          ),
        );
      } else if (mounted) {
        _showSnackBar('Presença removida', color: Colors.orangeAccent);
      }

      setState(() {});
    } catch (e) {
      _showSnackBar('Erro ao marcar presença: $e');
    }
  }

  Future<void> _abrirDetalheJogo(String jogoId) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => JogoDetalhe(jogoId: jogoId)));
    setState(() {});
  }

  Future<void> _carregarJogos() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('jogos')
          .where('ativo', isEqualTo: true)
          .get();

      final List<Marker> newMarkers = [];
      int processedCount = 0;

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final jogoId = doc.id;
          final local = data['local'] as String? ?? 'Local desconhecido';
          final dataJogo = (data['data'] as Timestamp?)?.toDate();
          final maxJogadores = (data['jogadores'] as num?)?.toInt() ?? 0;
          final lat = (data['lat'] as num?)?.toDouble();
          final lon = (data['lon'] as num?)?.toDouble();

          _jogosData[jogoId] = {
            'local': local,
            'dataJogo': dataJogo,
            'maxJogadores': maxJogadores,
          };

          double? useLat = lat;
          double? useLon = lon;

          if ((useLat == null || useLon == null) && processedCount < 10) {
            try {
              final posicoes = await locationFromAddress(
                '$local, Portugal',
              ).timeout(const Duration(seconds: 5));
              if (posicoes.isNotEmpty) {
                useLat = posicoes.first.latitude;
                useLon = posicoes.first.longitude;

                unawaited(
                  doc.reference
                      .update({'lat': useLat, 'lon': useLon})
                      .catchError(
                        (e) => debugPrint('Erro ao guardar coordenadas: $e'),
                      ),
                );
              }
            } catch (e) {
              debugPrint('Erro na geocodificação de $local: $e');
            }
          }

          if (useLat != null && useLon != null) {
            // Buscar previsão do tempo
            String weatherInfo = '';
            if (dataJogo != null) {
              try {
                final forecast = await WeatherService()
                    .getForecastAt(useLat, useLon, dataJogo)
                    .timeout(const Duration(seconds: 3));

                if (forecast != null) {
                  final desc = (forecast['desc'] as String?) ?? '';
                  final temp = forecast['temp'];
                  if (desc.isNotEmpty) {
                    weatherInfo =
                        ' • ${desc[0].toUpperCase()}${desc.substring(1)} $temp°C';
                  } else {
                    weatherInfo = ' • $temp°C';
                  }
                }
              } catch (e) {
                debugPrint('Erro ao obter previsão do tempo: $e');
              }
            }

            // Formatar data e hora
            String dataHoraInfo = '';
            if (dataJogo != null) {
              final dia = dataJogo.day.toString().padLeft(2, '0');
              final mes = dataJogo.month.toString().padLeft(2, '0');
              final hora = dataJogo.hour.toString().padLeft(2, '0');
              final minuto = dataJogo.minute.toString().padLeft(2, '0');
              dataHoraInfo = '$dia/$mes $hora:$minuto';
            } else {
              dataHoraInfo = 'Data não definida';
            }

            newMarkers.add(
              Marker(
                markerId: MarkerId(jogoId),
                position: LatLng(useLat, useLon),
                // REMOVIDO: onTap já não abre o detalhe
                // onTap: () => _abrirDetalheJogo(jogoId),
                infoWindow: InfoWindow(
                  title: local,
                  snippet:
                      '$dataHoraInfo$weatherInfo', // Mostra data/hora + tempo
                  onTap: () =>
                      _abrirDetalheJogo(jogoId), // Só abre ao clicar na tooltip
                ),
              ),
            );
          }
          processedCount++;
        } catch (e) {
          debugPrint('Erro ao processar documento ${doc.id}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _marcadores.addAll(newMarkers);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar jogos: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Stack(
        children: [
          // Mapa
          if (_mapInitialized && _errorMessage == null)
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _inicio,
              markers: _marcadores,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              minMaxZoomPreference: const MinMaxZoomPreference(3, 18),
              trafficEnabled: false,
              buildingsEnabled: true,
              indoorViewEnabled: false,
              padding: const EdgeInsets.only(top: 40),
            ),

          // Loading overlay
          if (_loading)
            Container(
              color: const Color(0xFF0F172A).withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'A carregar mapa...',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Mensagem de erro
          if (_errorMessage != null)
            Container(
              color: const Color(0xFF0F172A),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _errorMessage = null;
                            _initializeMap();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                        ),
                        child: const Text('TENTAR NOVAMENTE'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Contador de jogos
          if (_mapInitialized && _errorMessage == null && !_loading)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${_marcadores.length} jogo${_marcadores.length != 1 ? 's' : ''}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Botão de localização
          if (_mapInitialized && _errorMessage == null && !_loading)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'btn-localizacao',
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                onPressed: _goToUserLocation,
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
        ],
      ),
    );
  }
}
