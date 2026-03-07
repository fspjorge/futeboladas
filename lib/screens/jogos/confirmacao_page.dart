import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../widgets/grid_backdrop.dart';

class ConfirmacaoJogoPage extends StatelessWidget {
  final String titulo;
  final DateTime data;
  final String local;
  final double? preco;
  final String? weather;
  final String? campo; // ← NOVO

  const ConfirmacaoJogoPage({
    super.key,
    required this.titulo,
    required this.data,
    required this.local,
    this.preco,
    this.weather,
    this.campo,
  });

  String _formatarPreco(double? preco) {
    if (preco == null || preco <= 0) return 'Grátis';
    return '€ ${preco.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
          // Background Backdrop
          Positioned.fill(child: Container(color: const Color(0xFF0F172A))),
          Positioned.fill(
            child: Opacity(opacity: 0.03, child: const GridBackdrop()),
          ),

          // Content
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated Success Icon with Glass background
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cs.primary.withValues(alpha: 0.15),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 56,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          Text(
                            'PRESENÇA CONFIRMADA!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Estás dentro da convocatória. Prepara as chuteiras!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.white38,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Game Summary Card
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildInfoMini(Icons.sports_soccer, titulo),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Divider(
                                        color: Colors.white10,
                                        height: 1,
                                      ),
                                    ),
                                    _buildInfoMini(Icons.place_outlined, local),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Divider(
                                        color: Colors.white10,
                                        height: 1,
                                      ),
                                    ),
                                    _buildInfoMini(
                                      Icons.schedule_outlined,
                                      DateFormat(
                                        "EEEE, d 'de' MMMM 'às' HH:mm",
                                        'pt_PT',
                                      ).format(data),
                                    ),
                                    if (campo != null) ...[
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Divider(
                                          color: Colors.white10,
                                          height: 1,
                                        ),
                                      ),
                                      _buildInfoMini(
                                        Icons.stadium_outlined,
                                        campo!,
                                      ),
                                    ],
                                    if (preco != null) ...[
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
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
                                    if (weather != null &&
                                        weather!.isNotEmpty) ...[
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Divider(
                                          color: Colors.white10,
                                          height: 1,
                                        ),
                                      ),
                                      _buildInfoMini(
                                        Icons.cloud_outlined,
                                        weather!,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMini(IconData icon, String text, {Color? valorCor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white38),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: valorCor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
