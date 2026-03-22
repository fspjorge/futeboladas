import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  final Future<Map<String, dynamic>?>? weather;

  const GameDetailHeader({
    super.key,
    required this.title,
    required this.location,
    this.date,
    required this.price,
    this.field,
    this.lat,
    this.lon,
    this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: GridBackdrop()),
        Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 24,
            right: 24,
            bottom: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              // Linha 1: Data e Hora
              _headerInfoRow(
                Icons.calendar_today_outlined,
                date != null
                    ? DateFormat(
                        "EEEE, d 'de' MMMM 'às' HH:mm",
                        'pt_PT',
                      ).format(date!)
                    : 'Sem data',
              ),
              const SizedBox(height: 10),
              // Linha 2: Tipo de Campo
              _headerInfoRow(
                Icons.stadium_outlined,
                field ?? 'Relva Sintética',
              ),
              const SizedBox(height: 10),
              // Linha 3: Meteorologia
              if (weather != null)
                FutureBuilder<Map<String, dynamic>?>(
                  future: weather,
                  builder: (context, weatherSnap) {
                    if (weatherSnap.connectionState ==
                        ConnectionState.waiting) {
                      return _headerInfoRow(
                        Icons.cloud_outlined,
                        'À procura de previsão...',
                        iconColor: Colors.white24,
                      );
                    }

                    if (weatherSnap.hasError) {
                      return _headerInfoRow(
                        Icons.cloud_off_outlined,
                        'Meteorologia Indisponível',
                        iconColor: Colors.white24,
                      );
                    }

                    if (!weatherSnap.hasData || weatherSnap.data == null) {
                      return _headerInfoRow(
                        Icons.info_outline,
                        'Previsão indisponível',
                        iconColor: Colors.white24,
                      );
                    }

                    final w = weatherSnap.data!;
                    final desc = w['desc'] as String?;
                    final temp = w['temp'];
                    final diaNoite = w['diaNoite'];

                    final capitalizedDesc = desc != null && desc.isNotEmpty
                        ? '${desc[0].toUpperCase()}${desc.substring(1)}'
                        : '';
                    final text = '$capitalizedDesc, $temp°C';
                    final icon = diaNoite == 'Noite'
                        ? Icons.nightlight_round
                        : Icons.wb_sunny_rounded;
                    final iconColor = Colors.amber;

                    return _headerInfoRow(icon, text, iconColor: iconColor);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerInfoRow(IconData icon, String text, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor ?? Colors.white38),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
