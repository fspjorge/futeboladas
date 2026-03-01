import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'jogo_detalhe.dart';
import '../../widgets/glass_card.dart';

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
  String? _selectedJogoId;

  static const CameraPosition _inicio = CameraPosition(
    target: LatLng(38.7169, -9.1399),
    zoom: 7,
  );

  String _formatarPreco(num? preco) {
    if (preco == null || preco <= 0) return 'Grátis';
    return '€ ${preco.toStringAsFixed(2)}';
  }

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
        content: Text(
          message,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: color != null ? Colors.white : const Color(0xFF111827),
            fontSize: 14,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color ?? const Color(0xFFF3F4F6),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
      _jogosData.clear();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final jogoId = doc.id;
          final local = data['local'] as String? ?? 'Local desconhecido';
          final dataJogo = (data['data'] as Timestamp?)?.toDate();
          final maxJogadores = (data['jogadores'] as num?)?.toInt() ?? 0;
          final preco = (data['preco'] as num?)?.toDouble() ?? 0.0;

          double? lat = (data['lat'] as num?)?.toDouble();
          double? lon = (data['lon'] as num?)?.toDouble();

          // Se não tem coordenadas, tenta geocodificar (limite suave para não abusar)
          if (lat == null || lon == null) {
            try {
              final posicoes = await locationFromAddress(
                '$local, Portugal',
              ).timeout(const Duration(seconds: 5));
              if (posicoes.isNotEmpty) {
                lat = posicoes.first.latitude;
                lon = posicoes.first.longitude;
                unawaited(doc.reference.update({'lat': lat, 'lon': lon}));
              }
            } catch (e) {
              debugPrint('Erro na geocodificação de $local: $e');
            }
          }

          if (lat != null && lon != null) {
            _jogosData[jogoId] = {
              'titulo': data['titulo'] as String? ?? local,
              'local': local,
              'dataJogo': dataJogo,
              'maxJogadores': maxJogadores,
              'preco': preco,
              'lat': lat,
              'lon': lon,
            };

            newMarkers.add(
              Marker(
                markerId: MarkerId(jogoId),
                position: LatLng(lat, lon),
                onTap: () {
                  setState(() {
                    _selectedJogoId = jogoId;
                  });
                },
              ),
            );
          }
        } catch (e) {
          debugPrint('Erro ao processar documento ${doc.id}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _marcadores.clear();
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
              onTap: (_) {
                if (_selectedJogoId != null) {
                  setState(() => _selectedJogoId = null);
                }
              },
              minMaxZoomPreference: const MinMaxZoomPreference(3, 18),
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
                      const Icon(
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

          // Floating Jogo Card
          if (_selectedJogoId != null &&
              _jogosData.containsKey(_selectedJogoId))
            _buildSelectedJogoCard(),

          // Botão de localização
          if (_mapInitialized && _errorMessage == null && !_loading)
            Positioned(
              bottom: _selectedJogoId != null ? 220 : 20,
              right: 20,
              child: FloatingActionButton(
                mini: _selectedJogoId != null,
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

  Widget _buildSelectedJogoCard() {
    final data = _jogosData[_selectedJogoId!];
    if (data == null) return const SizedBox.shrink();

    final titulo = data['titulo'] as String;
    final local = data['local'] as String;
    final dataJogo = data['dataJogo'] as DateTime?;
    final preco = data['preco'] as num? ?? 0;
    final lat = data['lat'] as double?;
    final lon = data['lon'] as double?;

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: GlassCard(
        color: const Color(0xFF0F172A),
        opacity: 0.6,
        blur: 20,
        child: InkWell(
          onTap: () => _abrirDetalheJogo(_selectedJogoId!),
          borderRadius: BorderRadius.circular(20), // Matches GlassCard default
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titulo.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white38,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _selectedJogoId = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(
                  local,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMiniInfo(
                      Icons.calendar_today_outlined,
                      dataJogo != null
                          ? DateFormat('dd/MM HH:mm').format(dataJogo)
                          : '---',
                    ),
                    const SizedBox(width: 8),
                    _buildMiniInfo(
                      Icons.stadium_outlined,
                      (data['campo'] as String? ?? 'Relva Sintética')
                          .replaceAll('Relva ', ''),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: preco > 0
                            ? Colors.green.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatarPreco(preco),
                        style: GoogleFonts.outfit(
                          color: preco > 0
                              ? Colors.greenAccent
                              : Colors.blueAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white24,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
