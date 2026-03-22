import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/weather_service.dart';
import '../../../widgets/grid_backdrop.dart';
import '../../../utils/format_utils.dart';

class GameDetailHeader extends StatelessWidget {
  final String title;
  final String location;
  final DateTime? date;
  final num price;
  final String? field;
  final double? lat;
  final double? lon;

  const GameDetailHeader({
    super.key,
    required this.title,
    required this.location,
    this.date,
    required this.price,
    this.field,
    this.lat,
    this.lon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      decoration: const BoxDecoration(
        color: Colors
            .transparent, // Background provided by parent (Scaffold/Stack)
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: GridBackdrop()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'JOGO CONFIRMADO',
                          style: GoogleFonts.outfit(
                            color: cs.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: price > 0
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: price > 0
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          FormatUtils.formatarPreco(price),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: price > 0 ? Colors.green : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                                  ).format(date!)
                                : 'Sem data',
                            style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stadium_outlined,
                            size: 16,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            field ?? 'Relva Sintética',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (lat != null && lon != null && date != null)
                    FutureBuilder<Map<String, dynamic>?>(
                      future: WeatherService().getForecastAt(lat!, lon!, date!),
                      builder: (context, weatherSnap) {
                        if (!weatherSnap.hasData || weatherSnap.data == null) {
                          return const SizedBox.shrink();
                        }
                        final w = weatherSnap.data!;
                        return Row(
                          children: [
                            Icon(
                              w['diaNoite'] == 'Noite'
                                  ? Icons.nightlight_round
                                  : Icons.wb_sunny_rounded,
                              size: 16,
                              color: Colors.amber.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${w['temp']}°C • ${w['desc']}',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
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
      ),
    );
  }
}
