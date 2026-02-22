class Config {
  /// Chave de API do Google Places.
  /// Tenta ler de --dart-define=PLACES_API_KEY.
  /// Podes colocar a tua chave real aqui como fallback para facilitar o desenvolvimento.
  static const String googlePlacesApiKey = String.fromEnvironment(
    'PLACES_API_KEY',
    defaultValue:
        'AIzaSyAPRZImkhwXKE0lqBhYAUvlBXKLN-UbnYk', // Tua chave atual detetada
  );

  /// Chave de API do OpenWeather (se quiseres centralizar também).
  static const String weatherApiKey = '95b510c31a587dd623df9ec238d300cd';
}
