import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' show ImageFilter;

import '../../models/game.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/game_service.dart';
import '../../services/weather_service.dart';
import '../../widgets/grid_backdrop.dart';
import 'widgets/admin_section.dart';
import 'widgets/game_detail_header.dart';
import 'widgets/game_detail_info.dart';
import 'widgets/game_detail_players.dart';
import 'widgets/game_detail_actions.dart';

class GameDetail extends StatefulWidget {
  final String gameId;
  const GameDetail({super.key, required this.gameId});

  @override
  State<GameDetail> createState() => _JogoDetalheState();
}

class _JogoDetalheState extends State<GameDetail> {
  bool _deleting = false;
  int _reminderMin = 5;

  Future<Map<String, dynamic>?>? _weatherFuture;
  double? _lastLat;
  double? _lastLon;
  DateTime? _lastDate;

  void _updateWeather(double? lat, double? lon, DateTime? date) {
    // Se as coordenadas ou data forem as mesmas, não refaz o fetch
    final sameLat = lat == _lastLat;
    final sameLon = lon == _lastLon;
    final sameDate =
        date?.millisecondsSinceEpoch == _lastDate?.millisecondsSinceEpoch;

    // Se tudo for igual E já tivermos uma future inicializada, não fazemos nada
    if (sameLat && sameLon && sameDate && _weatherFuture != null) {
      return;
    }

    _lastLat = lat;
    _lastLon = lon;
    _lastDate = date;

    if (lat != null && lon != null && date != null) {
      _weatherFuture = WeatherService().getForecastAt(lat, lon, date);
    } else {
      _weatherFuture = null;
    }
  }

  Future<void> _pickReminder() async {
    final opts = const [0, 5, 10, 15, 30, 60];
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: const Color(0xFF0F172A).withValues(alpha: 0.95),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'LEMBRETE',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ...opts.map(
                    (m) => ListTile(
                      title: Text(
                        m == 0 ? 'No momento do evento' : '$m minutos antes',
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () => Navigator.pop(ctx, m),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (picked != null) {
      setState(() => _reminderMin = picked);
    }
  }

  Future<void> _eliminarJogo() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Apagar Jogo',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: const Text(
          'Tens a certeza? Esta ação é permanente e irá remover todas as presenças.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('APAGAR'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _deleting = true);
    try {
      await GameService.instance.apagarJogo(widget.gameId);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jogo apagado com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao apagar: $e')));
      }
    }
  }

  Future<void> _openMaps(String location) async {
    try {
      final res = await locationFromAddress('$location, Portugal');
      if (res.isNotEmpty) {
        final pos = LatLng(res.first.latitude, res.first.longitude);
        final uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}',
        );
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Localização não encontrada');
      }
    } catch (e) {
      final query = Uri.encodeComponent(location);
      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$query',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.id;
    final presencas = AttendanceService();
    final gameService = GameService.instance;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xFF0F172A))),
          Positioned.fill(child: const GridBackdrop()),
          StreamBuilder<Game?>(
            stream: gameService.jogoStream(widget.gameId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final game = snap.data;
              if (game == null) {
                if (_deleting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Center(
                  child: Text(
                    'Jogo não encontrado.',
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 18,
                    ),
                  ),
                );
              }

              final location = game.location;
              final date = game.date;
              final createdBy = game.createdBy;
              final isOwner = uid != null && createdBy == uid;
              final price = game.price ?? 0;
              final lat = game.lat;
              final lon = game.lon;

              _updateWeather(lat, lon, date);

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        GameDetailHeader(
                          title: game.title,
                          location: location,
                          date: date,
                          price: price,
                          field: game.field,
                          lat: lat,
                          lon: lon,
                          weather: _weatherFuture,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GameDetailInfo(
                                gameId: widget.gameId,
                                game: game,
                                presencas: presencas,
                                onPickReminder: _pickReminder,
                                reminderMin: _reminderMin,
                                onOpenMaps: _openMaps,
                                weather: _weatherFuture,
                                uid: uid,
                              ),
                              if (uid != null)
                                GameDetailPlayers(
                                  gameId: widget.gameId,
                                  createdBy: createdBy,
                                  uid: uid,
                                ),
                              const SizedBox(height: 24),
                              if (isOwner)
                                AdminSection(
                                  gameId: widget.gameId,
                                  onEliminar: _eliminarJogo,
                                ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GameDetailActions(
                    presencas: presencas,
                    gameId: widget.gameId,
                    title: game.title,
                    location: location,
                    date: date,
                    lat: lat,
                    lon: lon,
                    field: game.field,
                    price: price.toDouble(),
                    maxParticipantes: game.players,
                    participants:
                        const [], // Buscado via stream em GameDetailActions
                    organizadorNome: game.createdByName,
                    organizadorFoto: game.createdByPhoto,
                  ),
                ],
              );
            },
          ),

          if (_deleting)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
