import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/attendance_service.dart';
import '../../../main.dart';

class GameDetailActions extends StatelessWidget {
  final AttendanceService presencas;
  final String gameId;
  final String title;
  final String location;
  final DateTime? date;
  final double? lat;
  final double? lon;
  final String? field; // ← NOVO
  final double? price; // ← NOVO
  final int? maxParticipantes; // ← NOVO
  final List<String>? participants; // ← NOVO
  final String? organizadorNome; // ← NOVO
  final String? organizadorFoto; // ← NOVO

  const GameDetailActions({
    super.key,
    required this.presencas,
    required this.gameId,
    required this.title,
    required this.location,
    this.date,
    this.lat,
    this.lon,
    this.field,
    this.price,
    this.maxParticipantes,
    this.participants,
    this.organizadorNome,
    this.organizadorFoto,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: StreamBuilder<bool>(
          stream: presencas.minhaPresenca(gameId),
          builder: (context, snap) {
            final isGoing = snap.data ?? false;
            final isLoading = snap.connectionState == ConnectionState.waiting;
            return SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () => _handleAction(context, isGoing, cs),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGoing ? Colors.white12 : cs.primary,
                  foregroundColor: isGoing
                      ? Colors.white
                      : const Color(0xFF0F172A),
                  elevation: isGoing ? 0 : 2,
                  shadowColor: cs.primary.withValues(alpha: 0.3),
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

  Future<void> _handleAction(
    BuildContext context,
    bool isGoing,
    ColorScheme cs,
  ) async {
    await presencas.markAttendance(gameId, !isGoing);

    if (!context.mounted) return;

    if (isGoing) {
      scaffoldMessengerKey.currentState?.clearSnackBars();

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Presença removida de: $title'),
          duration: const Duration(seconds: 3),
          dismissDirection: DismissDirection.horizontal,
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
      scaffoldMessengerKey.currentState?.clearSnackBars();
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Presença confirmada em $title! ⚽')),
            ],
          ),
          backgroundColor: cs.primary,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    }
  }
}
