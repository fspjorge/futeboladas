class Config {
  /// Chave de API do Google Places.
  /// Lida de --dart-define=PLACES_API_KEY.
  static const String googlePlacesApiKey = String.fromEnvironment(
    'PLACES_API_KEY',
  );

  /// Chave de API do OpenWeather.
  /// Lida de --dart-define=WEATHER_API_KEY.
  static const String weatherApiKey = String.fromEnvironment('WEATHER_API_KEY');
}
