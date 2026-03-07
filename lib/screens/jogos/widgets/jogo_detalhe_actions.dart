import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/presenca_service.dart';
import '../../../services/weather_service.dart';
import '../confirmacao_page.dart';
import '../../../main.dart';

class JogoDetalheActions extends StatelessWidget {
  final PresencaService presencas;
  final String jogoId;
  final String titulo;
  final String local;
  final DateTime? date;
  final double? lat;
  final double? lon;
  final String? campo; // ← NOVO
  final double? preco; // ← NOVO

  const JogoDetalheActions({
    super.key,
    required this.presencas,
    required this.jogoId,
    required this.titulo,
    required this.local,
    this.date,
    this.lat,
    this.lon,
    this.campo,
    this.preco,
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
    await presencas.marcarPresenca(jogoId, !isGoing);

    if (!context.mounted) return;

    if (isGoing) {
      scaffoldMessengerKey.currentState?.clearSnackBars();

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Presença removida de: $titulo'),
          duration: const Duration(seconds: 3),
          dismissDirection: DismissDirection.horizontal,
          action: SnackBarAction(
            label: 'ANULAR',
            onPressed: () {
              presencas.marcarPresenca(jogoId, true);
              scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
            },
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } else {
      String? weatherStr;
      if (lat != null && lon != null && date != null) {
        final w = await WeatherService().getForecastAt(lat!, lon!, date!);
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
              titulo: titulo,
              data: date ?? DateTime.now(),
              local: local,
              weather: weatherStr,
              campo: campo,
              preco: preco,
            ),
          ),
        );
      }
    }
  }
}
