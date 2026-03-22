import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui' show ImageFilter;

import '../../../models/game.dart';
import '../game_detail.dart';
import '../../../services/attendance_service.dart';
import '../../../utils/format_utils.dart';
import '../../../main.dart';

class GameCard extends StatelessWidget {
  final Game game;
  final AttendanceService presencas;
  final String? uid;

  const GameCard({
    super.key,
    required this.game,
    required this.presencas,
    this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final location = game.location;
    final maxJogadores = game.players;
    final price = game.price ?? 0;
    final date = game.date;
    final gameId = game.id;
    final hora = DateFormat('HH:mm').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => GameDetail(gameId: gameId)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      hora,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.white.withValues(alpha: 0.06),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: presencas.countConfirmados(gameId),
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
                              location,
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
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: isFull
                                              ? cs.error
                                              : Colors.white24,
                                        ),
                                      ),
                                    ] else
                                      Text(
                                        '$confirmados players',
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
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: price > 0
                                        ? Colors.green.withValues(alpha: 0.08)
                                        : Colors.blue.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    FormatUtils.formatarPreco(price),
                                    style: GoogleFonts.outfit(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: price > 0
                                          ? Colors.green.withValues(alpha: 0.8)
                                          : Colors.blue.withValues(alpha: 0.8),
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
                                          (game.field ?? 'Relva Sintética')
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
                      stream: presencas.countConfirmados(gameId),
                      builder: (context, countSnap) {
                        final confirmados = countSnap.data ?? 0;
                        final bool isFull =
                            maxJogadores > 0 && confirmados >= maxJogadores;
                        return StreamBuilder<bool>(
                          stream: presencas.minhaPresenca(gameId),
                          builder: (context, meSnap) {
                            final isGoing = meSnap.data ?? false;
                            return _JoinButton(
                              isGoing: isGoing,
                              isFull: isFull,
                              onTap: () => _handlePresenceTap(
                                context,
                                isGoing,
                                isFull,
                                game,
                                date,
                                gameId,
                                location,
                                price,
                                maxJogadores,
                                confirmados,
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
    Game game,
    DateTime date,
    String gameId,
    String location,
    num price,
    int maxJogadores,
    int confirmados,
  ) async {
    try {
      if (!isGoing && isFull) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este jogo já está lotado!')),
        );
        return;
      }
      await presencas.markAttendance(gameId, !isGoing);

      if (!context.mounted) return;

      if (isGoing) {
        // Usa a chave global para garantir que o SnackBar funciona bem em transições
        scaffoldMessengerKey.currentState?.clearSnackBars();

        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Presença removida de: ${game.title}'),
            duration: const Duration(seconds: 3),
            dismissDirection:
                DismissDirection.horizontal, // Mais fácil de limpar
            action: SnackBarAction(
              label: 'ANULAR',
              onPressed: () {
                presencas.markAttendance(gameId, true);
                scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
              },
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      } else {
        if (context.mounted) {
          // Hide snackbar if any before navigating to avoid dismissal issues
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Presença confirmada em ${game.title}! ⚽'),
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(0, 32), // Compact height
          side: const BorderSide(color: Colors.white24),
          foregroundColor: Colors.white60,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 10, // Compact font
            fontWeight: FontWeight.w900,
          ),
        ),
        child: const Text('SAIR'),
      );
    }

    return ElevatedButton(
      onPressed: isFull ? null : onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 32), // Compact height
        backgroundColor: isFull ? Colors.white10 : cs.primary,
        foregroundColor: isFull ? Colors.white24 : const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: isFull ? 0 : 2,
      ),
      child: Text(
        isFull ? 'LOTADO' : 'IR',
        style: GoogleFonts.outfit(
          fontSize: 10, // Compact font
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
