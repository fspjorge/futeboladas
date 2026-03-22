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
    if (dotenv.isInitialized) {
      return dotenv.maybeGet('WEATHER_API_KEY') ??
          const String.fromEnvironment(
            'WEATHER_API_KEY',
            defaultValue: 'f2dc748e1f02e0e07a7be69b4fdd9e5c',
          );
    }
    return const String.fromEnvironment(
      'WEATHER_API_KEY',
      defaultValue: 'f2dc748e1f02e0e07a7be69b4fdd9e5c',
    );
  }

  /// URL do projeto Supabase.
  static String get supabaseUrl => dotenv.maybeGet('SUPABASE_URL') ?? '';

  /// Chave Anónima do Supabase.
  static String get supabaseAnonKey =>
      dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

  /// Google Web Client ID for native login.
  static String get googleWebClientId =>
      dotenv.maybeGet('GOOGLE_WEB_CLIENT_ID') ??
      '704341845387-phrtrpoc86e4d8f1jkmd7unv28vo18vt.apps.googleusercontent.com';
}
