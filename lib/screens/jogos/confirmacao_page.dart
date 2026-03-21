import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../widgets/grid_backdrop.dart';

class ConfirmacaoJogoPage extends StatelessWidget {
  final String titulo;
  final DateTime data;
  final String local;
  final Future<String?>? weather; // ← ALTERADO para Future
  final double? preco;
  final String? campo;
  final int? maxParticipantes; // ← NOVO
  final int? numParticipantes; // ← NOVO
  final String? organizadorNome; // ← NOVO
  final String? organizadorFoto; // ← NOVO
  final String? contactosPrivados; // ← NOVO
  final String? notasPrivadas; // ← NOVO

  const ConfirmacaoJogoPage({
    super.key,
    required this.titulo,
    required this.data,
    required this.local,
    this.weather,
    this.preco,
    this.campo,
    this.maxParticipantes,
    this.numParticipantes,
    this.organizadorNome,
    this.organizadorFoto,
    this.contactosPrivados,
    this.notasPrivadas,
  });

  String _formatarPreco(double? preco) {
    if (preco == null || preco == 0) return 'Grátis';
    return '${preco.toStringAsFixed(2)}€';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dataStr = DateFormat('EEEE, d MMMM', 'pt_PT').format(data);
    final horaStr = DateFormat('HH:mm').format(data);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          const GridBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white10,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Presença Confirmada!',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Estás convocado para entrar em campo.',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.white38,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Game Card Summary
                  Text(
                    'RESUMO DO JOGO',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white24,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildInfoMini(
                              Icons.calendar_today_outlined,
                              '$dataStr às $horaStr',
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Colors.white10, height: 1),
                            ),
                            _buildInfoMini(Icons.place_outlined, local),
                            if (campo != null) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: Colors.white10,
                                  height: 1,
                                ),
                              ),
                              _buildInfoMini(Icons.stadium_outlined, campo!),
                            ],
                            if (maxParticipantes != null &&
                                numParticipantes != null) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: Colors.white10,
                                  height: 1,
                                ),
                              ),
                              _buildInfoMini(
                                Icons.people_outline,
                                '$numParticipantes de $maxParticipantes jogadores',
                                valorCor: numParticipantes! >= maxParticipantes!
                                    ? Colors.orangeAccent
                                    : Colors.blueAccent,
                              ),
                            ],
                            if (preco != null) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: Colors.white10,
                                  height: 1,
                                ),
                              ),
                              _buildInfoMini(
                                Icons.euro_rounded,
                                _formatarPreco(preco),
                                valorCor: preco! > 0
                                    ? Colors.green
                                    : Colors.blue,
                              ),
                            ],
                            if (weather != null) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: Colors.white10,
                                  height: 1,
                                ),
                              ),
                              FutureBuilder<String?>(
                                future: weather,
                                builder: (context, snapshot) {
                                  final text = snapshot.data ?? 'A carregar...';
                                  return _buildInfoMini(
                                    Icons.cloud_outlined,
                                    text,
                                    isPending:
                                        snapshot.connectionState ==
                                        ConnectionState.waiting,
                                  );
                                },
                              ),
                            ],
                            if (organizadorNome != null) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: Colors.white10,
                                  height: 1,
                                ),
                              ),
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: organizadorFoto != null
                                        ? Image.network(
                                            organizadorFoto!,
                                            width: 18,
                                            height: 18,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                  Icons.person,
                                                  size: 18,
                                                  color: Colors.white38,
                                                ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            size: 18,
                                            color: Colors.white38,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Org: $organizadorNome',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (contactosPrivados != null || notasPrivadas != null) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Text(
                        'DADOS DO ORGANIZADOR (PRIVADO)',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (contactosPrivados != null &&
                              contactosPrivados!.isNotEmpty) ...[
                            const Text(
                              'CONTACTOS',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              contactosPrivados!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            if (notasPrivadas != null &&
                                notasPrivadas!.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: Colors.white10,
                                  height: 1,
                                ),
                              ),
                          ],
                          if (notasPrivadas != null &&
                              notasPrivadas!.isNotEmpty) ...[
                            const Text(
                              'NOTAS / HISTÓRICO',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notasPrivadas!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      child: const Text('OK, VAMOS A ISSO!'),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMini(
    IconData icon,
    String text, {
    Color? valorCor,
    bool isPending = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white38),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isPending ? Colors.white24 : (valorCor ?? Colors.white),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
