import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = '95b510c31a587dd623df9ec238d300cd';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const String _forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  // Meteo atual (fallback)
  Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
    final uri = Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=pt');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else {
      return null;
    }
  }

  // Previsão aproximada à hora agendada (intervalos de 3h)
  Future<Map<String, dynamic>?> getForecastAt(
    double lat,
    double lon,
    DateTime whenLocal,
  ) async {
    try {
      final uri = Uri.parse('$_forecastUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=pt');
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;

      final data = json.decode(res.body) as Map<String, dynamic>;
      final list = (data['list'] as List<dynamic>?);
      if (list == null || list.isEmpty) return null;
      // Comparar sempre em UTC para evitar erros de timezone
      final whenUtc = whenLocal.toUtc();

      Map<String, dynamic>? best;
      int bestDiff = 1 << 62;

      for (final item in list) {
        final mp = item as Map<String, dynamic>;
        final dtUtc = DateTime.fromMillisecondsSinceEpoch(((mp['dt'] as num).toInt()) * 1000, isUtc: true);
        final diff = (dtUtc.millisecondsSinceEpoch - whenUtc.millisecondsSinceEpoch).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          best = mp;
        }
      }

      if (best == null) return null;

      final weather = (best['weather'] as List).first as Map<String, dynamic>;
      final desc = weather['description'] as String? ?? '';
      final temp = (best['main']?['temp'] as num?)?.round();
      final pod = (best['sys']?['pod'] as String?) ?? 'd'; // 'd' ou 'n'
      final diaNoite = pod == 'n' ? 'Noite' : 'Dia';

      return {
        'desc': desc,
        'temp': temp,
        'diaNoite': diaNoite,
      };
    } catch (_) {
      return null;
    }
  }
}

