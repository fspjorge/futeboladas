import 'dart:ui' show ImageFilter;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/presenca_service.dart';
import '../../services/jogo_service.dart';
import '../../widgets/grid_backdrop.dart';
import 'widgets/admin_section.dart';
import 'widgets/jogo_detalhe_header.dart';
import 'widgets/jogo_detalhe_info.dart';
import 'widgets/jogo_detalhe_players.dart';
import 'widgets/jogo_detalhe_actions.dart';

class JogoDetalhe extends StatefulWidget {
  final String jogoId;
  const JogoDetalhe({super.key, required this.jogoId});

  @override
  State<JogoDetalhe> createState() => _JogoDetalheState();
}

class _JogoDetalheState extends State<JogoDetalhe> {
  bool _deleting = false;
  int _reminderMin = 5;

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
      await JogoService.instance.apagarJogo(widget.jogoId);
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

  Future<void> _openMaps(String local) async {
    try {
      final res = await locationFromAddress('$local, Portugal');
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
      final query = Uri.encodeComponent(local);
      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$query',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final presencas = PresencaService();
    final jogoRef = FirebaseFirestore.instance
        .collection('jogos')
        .doc(widget.jogoId);

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
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: jogoRef.snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || !snap.data!.exists) {
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
              final data = snap.data!.data()!;
              final local = data['local'] as String? ?? 'Local desconhecido';
              final date = (data['data'] as Timestamp?)?.toDate();
              final createdBy = data['createdBy'] as String?;
              final isOwner = uid != null && createdBy == uid;
              final preco = data['preco'] as num? ?? 0;

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        JogoDetalheHeader(
                          titulo: data['titulo'] as String? ?? local,
                          local: local,
                          date: date,
                          preco: preco,
                          campo: data['campo'] as String?,
                          lat: (data['lat'] as num?)?.toDouble(),
                          lon: (data['lon'] as num?)?.toDouble(),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              JogoDetalheInfo(
                                jogoId: widget.jogoId,
                                data: data,
                                presencas: presencas,
                                onPickReminder: _pickReminder,
                                reminderMin: _reminderMin,
                                onOpenMaps: _openMaps,
                              ),
                              const SizedBox(height: 24),
                              if (uid != null)
                                JogoDetalhePlayers(
                                  jogoRef: jogoRef,
                                  createdBy: createdBy,
                                  uid: uid,
                                ),
                              const SizedBox(height: 24),
                              if (isOwner)
                                AdminSection(
                                  jogoId: widget.jogoId,
                                  onEliminar: _eliminarJogo,
                                  jogoRef: jogoRef,
                                ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  JogoDetalheActions(
                    presencas: presencas,
                    jogoId: widget.jogoId,
                    titulo: data['titulo'] as String? ?? local,
                    local: local,
                    date: date,
                    lat: (data['lat'] as num?)?.toDouble(),
                    lon: (data['lon'] as num?)?.toDouble(),
                    campo: data['campo'] as String?,
                    preco: (data['preco'] as num?)?.toDouble(),
                    maxParticipantes: (data['jogadores'] as num?)?.toInt(),
                    participantes: List<String>.from(
                      data['participantes'] ?? [],
                    ),
                    organizadorNome: data['createdByName'] as String?,
                    organizadorFoto: data['createdByPhoto'] as String?,
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
