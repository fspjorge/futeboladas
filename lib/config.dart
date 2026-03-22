import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  /// Chave de API do Google Places.
  /// Lida de --dart-define=PLACES_API_KEY.
  static const String googlePlacesApiKey = String.fromEnvironment(
    'PLACES_API_KEY',
  );

  /// Chave de API do OpenWeather.
  /// Lida do ficheiro .env (via dotenv) ou fallback para --dart-define.
  static String get weatherApiKey {
    return dotenv.maybeGet('WEATHER_API_KEY') ??
        'f2dc748e1f02e0e07a7be69b4fdd9e5c';
  }
}
