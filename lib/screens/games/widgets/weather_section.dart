import 'package:flutter/material.dart';

class WeatherSection extends StatelessWidget {
  final Future<Map<String, dynamic>?>? forecast;
  final Widget Function(IconData icon, String label, String value)
  infoRowBuilder;

  const WeatherSection({
    super.key,
    required this.forecast,
    required this.infoRowBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: forecast,
      builder: (context, weatherSnap) {
        if (weatherSnap.connectionState == ConnectionState.waiting) {
          return infoRowBuilder(
            Icons.cloud_outlined,
            'Previsão',
            'A carregar...',
          );
        }
        if (weatherSnap.hasError) {
          return infoRowBuilder(
            Icons.cloud_off_outlined,
            'Previsão',
            'Erro de ligação',
          );
        }
        if (!weatherSnap.hasData || weatherSnap.data == null) {
          return infoRowBuilder(
            Icons.cloud_off_outlined,
            'Previsão',
            'Indisponível',
          );
        }
        final w = weatherSnap.data!;
        final desc = w['desc'] as String? ?? '';
        final capitalizedDesc = desc.isNotEmpty
            ? '${desc[0].toUpperCase()}${desc.substring(1)}'
            : '';

        return Column(
          children: [
            infoRowBuilder(
              Icons.cloud_outlined,
              'Previsão',
              '$capitalizedDesc, ${w['temp']}°C',
            ),
            const Divider(color: Colors.white10, height: 1),
          ],
        );
      },
    );
  }
}
