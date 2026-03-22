import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/glass_card.dart';
import '../../../services/game_service.dart';
import '../edit_game.dart';

class AdminSection extends StatefulWidget {
  final String gameId;
  final VoidCallback onEliminar;
  final DocumentReference<Map<String, dynamic>> jogoRef;

  const AdminSection({
    super.key,
    required this.gameId,
    required this.onEliminar,
    required this.jogoRef,
  });

  @override
  State<AdminSection> createState() => _AdminSectionState();
}

class _AdminSectionState extends State<AdminSection> {
  final _contactosCtrl = TextEditingController();
  final _historicoCtrl = TextEditingController();
  bool _adminLoaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _contactosCtrl.dispose();
    _historicoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                                      EditGame(gameId: widget.gameId),
                                ),
                              ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('EDITAR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 56),
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
                        onPressed: _saving ? null : widget.onEliminar,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('APAGAR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(
                            alpha: 0.1,
                          ),
                          foregroundColor: Colors.redAccent,
                          minimumSize: const Size(0, 56),
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
                  stream: widget.jogoRef
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
                            hintText: 'ex: Telemóvel do responsável do field',
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
                                      await GameService.instance.guardarAdmin(
                                        widget.gameId,
                                        contactos: _contactosCtrl.text,
                                        historico: _historicoCtrl.text,
                                      );
                                      if (context.mounted) {
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
                                      if (context.mounted) {
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
                                      if (mounted) {
                                        setState(() => _saving = false);
                                      }
                                    }
                                  },
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Color(0xFF0F172A),
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
}
