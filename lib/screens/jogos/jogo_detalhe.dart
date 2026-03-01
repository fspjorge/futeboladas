import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/presenca_service.dart';
import '../../services/jogo_service.dart';
import 'confirmacao_page.dart';
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
  bool _deleting = false;
  int _reminderMin = 5;

  @override
  void dispose() {
    _contactosCtrl.dispose();
    _historicoCtrl.dispose();
    super.dispose();
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
            color: const Color(0xFF0F172A).withOpacity(0.95),
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
        Navigator.of(context).pop(); // Back to dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jogo apagado com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao apagar: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
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
      // Fallback: abrir pesquisa Google Maps com o nome do local
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
          // Background
          Positioned.fill(child: Container(color: const Color(0xFF0F172A))),
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: CustomPaint(painter: _GridBackdropPainter()),
            ),
          ),
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
              final cs = Theme.of(context).colorScheme;

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildHeroHeader(local, date, cs),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoSection(context, data, presencas, cs),
                              const SizedBox(height: 24),
                              if (uid != null)
                                _buildPlayersList(jogoRef, createdBy, uid, cs),
                              const SizedBox(height: 24),
                              if (isOwner)
                                _buildAdminSection(jogoRef, data, cs),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildBottomAction(presencas, widget.jogoId, local, date, cs),
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

  Widget _buildHeroHeader(String local, DateTime? date, ColorScheme cs) {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cs.primary.withOpacity(0.2), const Color(0xFF0F172A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: _GridBackdropPainter()),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PARTIDA CONFIRMADA',
                      style: GoogleFonts.outfit(
                        color: cs.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    local,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.white38,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date != null
                            ? DateFormat(
                                "EEEE, d 'de' MMMM 'às' HH:mm",
                                'pt_PT',
                              ).format(date)
                            : 'Sem data',
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    Map<String, dynamic> data,
    PresencaService presencas,
    ColorScheme cs,
  ) {
    final local = data['local'] as String? ?? '';
    final maxJogadores = (data['jogadores'] as num?)?.toInt() ?? 0;
    final createdByName = data['createdByName'] as String? ?? 'Desconhecido';

    return GlassCard(
      child: Column(
        children: [
          _infoRow(
            Icons.place_outlined,
            'Localização',
            local,
            trailing: IconButton(
              icon: const Icon(Icons.directions, color: Colors.white70),
              onPressed: () => _openMaps(local),
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          StreamBuilder<int>(
            stream: presencas.countConfirmados(widget.jogoId),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return _infoRow(
                Icons.people_outline,
                'Equipas',
                '$count / $maxJogadores jogadores',
              );
            },
          ),
          const Divider(color: Colors.white10, height: 1),
          _infoRow(Icons.person_outline, 'Organizador', createdByName),
          const Divider(color: Colors.white10, height: 1),
          InkWell(
            onTap: _pickReminder,
            child: _infoRow(
              Icons.notifications_none,
              'Lembrete',
              _reminderMin == 0 ? 'No momento' : '$_reminderMin min antes',
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.white60),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildPlayersList(
    DocumentReference<Map<String, dynamic>> jogoRef,
    String? createdBy,
    String uid,
    ColorScheme cs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'JOGADORES CONFIRMADOS',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: jogoRef
              .collection('presencas')
              .where('vai', isEqualTo: true)
              .snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Ninguém confirmou ainda.',
                  style: GoogleFonts.outfit(
                    color: Colors.white24,
                    fontSize: 14,
                  ),
                ),
              );
            }
            return Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final name = d.data()['name'] as String? ?? 'Jogador';
                  final photo = d.data()['photo'] as String?;
                  final isOrg = d.id == createdBy;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: photo != null
                              ? NetworkImage(photo)
                              : null,
                          child: photo == null
                              ? const Icon(Icons.person, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: isOrg
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (isOrg)
                          Icon(Icons.verified, size: 14, color: cs.primary),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdminSection(
    DocumentReference<Map<String, dynamic>> jogoRef,
    Map<String, dynamic> gameData,
    ColorScheme cs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'ÁREA DO ORGANIZADOR',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      JogoEditar(jogoId: widget.jogoId),
                                ),
                              ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('EDITAR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white,
                          textStyle: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _eliminarJogo,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('APAGAR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          foregroundColor: Colors.redAccent,
                          textStyle: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: jogoRef
                      .collection('admin')
                      .doc('privado')
                      .snapshots(),
                  builder: (context, asnap) {
                    final adata = asnap.data?.data() ?? {};
                    if (!_adminLoaded && adata.isNotEmpty) {
                      _contactosCtrl.text =
                          (adata['contactos'] as String?) ?? '';
                      _historicoCtrl.text =
                          (adata['historico'] as String?) ?? '';
                      _adminLoaded = true;
                    }
                    return Column(
                      children: [
                        TextField(
                          controller: _contactosCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Contactos Privados',
                            hintText: 'ex: Telemóvel do responsável do campo',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _historicoCtrl,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Notas / Histórico',
                            hintText: 'ex: Ficou pago adiantado',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving
                                ? null
                                : () async {
                                    setState(() => _saving = true);
                                    try {
                                      await JogoService.instance.guardarAdmin(
                                        widget.jogoId,
                                        contactos: _contactosCtrl.text,
                                        historico: _historicoCtrl.text,
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Notas guardadas.',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Erro: $e'),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted)
                                        setState(() => _saving = false);
                                    }
                                  },
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('GUARDAR NOTAS'),
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
  }

  Widget _buildBottomAction(
    PresencaService presencas,
    String jogoId,
    String local,
    DateTime? date,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SafeArea(
        top: false,
        child: StreamBuilder<bool>(
          stream: presencas.minhaPresenca(jogoId),
          builder: (context, snap) {
            final isGoing = snap.data ?? false;
            final isLoading = snap.connectionState == ConnectionState.waiting;
            return SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        await presencas.marcarPresenca(jogoId, !isGoing);
                        if (!isGoing && mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ConfirmacaoJogoPage(
                                titulo: local,
                                data: date ?? DateTime.now(),
                                local: local,
                              ),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGoing ? Colors.white12 : cs.primary,
                  foregroundColor: isGoing
                      ? Colors.white
                      : const Color(0xFF0F172A),
                  elevation: isGoing ? 0 : 2,
                  shadowColor: cs.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isGoing ? 'DESMARCAR PRESENÇA' : 'CONFIRMAR PRESENÇA',
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GridBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
