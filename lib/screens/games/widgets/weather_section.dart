import 'package:flutter/material.dart';
import '../../../services/weather_service.dart';

class WeatherSection extends StatelessWidget {
  final double lat;
  final double lon;
  final DateTime date;
  final Widget Function(IconData icon, String label, String value)
  infoRowBuilder;

  const WeatherSection({
    super.key,
    required this.lat,
    required this.lon,
    required this.date,
    required this.infoRowBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: WeatherService().getForecastAt(lat, lon, date),
      builder: (context, weatherSnap) {
        if (!weatherSnap.hasData || weatherSnap.data == null) {
          return const SizedBox.shrink();
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
