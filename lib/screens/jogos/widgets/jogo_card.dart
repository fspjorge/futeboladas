import 'dart:ui' show ImageFilter;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../jogo_detalhe.dart';
import '../confirmacao_page.dart';
import '../../../services/presenca_service.dart';
import '../../../services/weather_service.dart';
import '../../../utils/format_utils.dart';

class JogoCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final PresencaService presencas;
  final String? uid;
  final VoidCallback? onPresenceChanged;

  const JogoCard({
    super.key,
    required this.doc,
    required this.presencas,
    this.uid,
    this.onPresenceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = doc.data();
    final local = data['local'] as String? ?? 'Local desconhecido';
    final maxJogadores = (data['jogadores'] as num?)?.toInt() ?? 0;
    final preco = data['preco'] as num? ?? 0;
    final date = (data['data'] as Timestamp).toDate();
    final jogoId = doc.id;
    final hora = DateFormat('HH:mm').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => JogoDetalhe(jogoId: jogoId)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      hora,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withValues(alpha: 0.08),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: presencas.countConfirmados(jogoId),
                      builder: (context, countSnap) {
                        final confirmados = countSnap.data ?? 0;
                        final bool hasLimit = maxJogadores > 0;
                        final bool isFull =
                            hasLimit && confirmados >= maxJogadores;
                        final dotColor = isFull ? cs.error : cs.primary;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              local,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (hasLimit) ...[
                                      ...List.generate(
                                        maxJogadores.clamp(0, 8),
                                        (i) => Container(
                                          margin: const EdgeInsets.only(
                                            right: 2,
                                          ),
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: i < confirmados
                                                ? dotColor
                                                : Colors.white.withValues(
                                                    alpha: 0.12,
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '$confirmados/$maxJogadores',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isFull
                                              ? cs.error
                                              : Colors.white30,
                                        ),
                                      ),
                                    ] else
                                      Text(
                                        '$confirmados jogadores',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: Colors.white30,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: preco > 0
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    FormatUtils.formatarPreco(preco),
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: preco > 0
                                          ? Colors.green
                                          : Colors.blue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.stadium_outlined,
                                        size: 10,
                                        color: Colors.white38,
                                      ),
                                      const SizedBox(width: 2),
                                      Flexible(
                                        child: Text(
                                          (data['campo'] as String? ??
                                                  'Relva Sintética')
                                              .replaceAll('Relva ', ''),
                                          style: GoogleFonts.outfit(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white30,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (uid != null)
                    StreamBuilder<int>(
                      stream: presencas.countConfirmados(jogoId),
                      builder: (context, countSnap) {
                        final confirmados = countSnap.data ?? 0;
                        final bool isFull =
                            maxJogadores > 0 && confirmados >= maxJogadores;
                        return StreamBuilder<bool>(
                          stream: presencas.minhaPresenca(jogoId),
                          builder: (context, meSnap) {
                            final isGoing = meSnap.data ?? false;
                            return _JoinButton(
                              isGoing: isGoing,
                              isFull: isFull,
                              onTap: () => _handlePresenceTap(
                                context,
                                isGoing,
                                isFull,
                                data,
                                date,
                                jogoId,
                                local,
                                preco,
                              ),
                              cs: cs,
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePresenceTap(
    BuildContext context,
    bool isGoing,
    bool isFull,
    Map<String, dynamic> data,
    DateTime date,
    String jogoId,
    String local,
    num preco,
  ) async {
    final cs = Theme.of(context).colorScheme;
    try {
      if (!isGoing && isFull) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este jogo já está lotado!')),
        );
        return;
      }
      await presencas.marcarPresenca(jogoId, !isGoing);

      if (onPresenceChanged != null) {
        onPresenceChanged!();
      }

      if (!context.mounted) return;

      if (isGoing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Presença removida de: ${data['titulo'] as String? ?? local}',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
                fontSize: 14,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFF3F4F6),
            elevation: 4,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'ANULAR',
              textColor: cs.primary,
              onPressed: () {
                presencas.marcarPresenca(jogoId, true);
                if (onPresenceChanged != null) {
                  onPresenceChanged!();
                }
              },
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        String? weatherStr;
        final lat = (data['lat'] as num?)?.toDouble();
        final lon = (data['lon'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          final w = await WeatherService().getForecastAt(lat, lon, date);
          if (w != null) {
            final desc = w['desc'] as String? ?? '';
            final capitalizedDesc = desc.isNotEmpty
                ? '${desc[0].toUpperCase()}${desc.substring(1)}'
                : '';
            weatherStr = '$capitalizedDesc, ${w['temp']}°C';
          }
        }

        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConfirmacaoJogoPage(
                titulo: data['titulo'] as String? ?? local,
                data: date,
                local: local,
                preco: preco.toDouble(),
                weather: weatherStr,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }
}

class _JoinButton extends StatelessWidget {
  final bool isGoing;
  final bool isFull;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _JoinButton({
    required this.isGoing,
    required this.isFull,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    if (isGoing) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: Colors.white24),
          foregroundColor: Colors.white60,
          textStyle: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: const Text('SAIR'),
      );
    }

    return ElevatedButton(
      onPressed: isFull ? null : onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: isFull ? Colors.white10 : cs.primary,
        foregroundColor: isFull ? Colors.white24 : const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      child: Text(
        isFull ? 'LOTADO' : 'IR',
        style: GoogleFonts.outfit(
          fontSize: isFull ? 10 : 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
