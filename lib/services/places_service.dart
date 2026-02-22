import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PlaceSuggestion {
  final String placeId;
  final String description;
  const PlaceSuggestion({required this.placeId, required this.description});
}

class PlaceLocation {
  final double lat;
  final double lon;
  const PlaceLocation({required this.lat, required this.lon});
}

class PlacesService {
  // Definir via: flutter run --dart-define=PLACES_API_KEY=TUA_CHAVE
  static const String _apiKey = String.fromEnvironment('PLACES_API_KEY');
  static const String _base = 'https://maps.googleapis.com/maps/api/place';

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Traduz erros comuns da Google Places API para mensagens amigáveis.
  static String mapError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('billing')) {
      return 'Faturação (Billing) não ativada no Google Cloud.';
    }
    if (msg.contains('invalid') ||
        msg.contains('key_not_valid') ||
        msg.contains('9011')) {
      return 'Chave de API inválida (Erro 9011). Verifica se a API de Places está ativa e sem restrições.';
    }
    if (msg.contains('denied') || msg.contains('not authorized')) {
      return 'Acesso negado. Verifica as permissões da API Key.';
    }
    return 'Erro na pesquisa de locais. Verifica a ligação.';
  }

  Future<List<PlaceSuggestion>> autocomplete(
    String query, {
    String? sessionToken,
    String language = 'pt',
    String country = 'pt',
  }) async {
    if (!isConfigured || query.isEmpty) return [];
    final session = sessionToken != null ? '&sessiontoken=$sessionToken' : '';
    final uri = Uri.parse(
      '$_base/autocomplete/json'
      '?input=${Uri.encodeComponent(query)}'
      '&key=$_apiKey'
      '&language=$language'
      '&components=country:$country'
      '$session',
    );
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        debugPrint(
          'PlacesService.autocomplete error ${res.statusCode}: ${res.body}',
        );
        return [];
      }
      final data = json.decode(res.body) as Map<String, dynamic>;
      final preds = (data['predictions'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(
            (p) => PlaceSuggestion(
              placeId: p['place_id'] as String,
              description: p['description'] as String,
            ),
          )
          .toList();
      return preds;
    } catch (e) {
      debugPrint('PlacesService.autocomplete exception: $e');
      return [];
    }
  }

  Future<PlaceLocation?> fetchPlaceLatLng(
    String placeId, {
    String? sessionToken,
  }) async {
    if (!isConfigured) return null;
    final session = sessionToken != null ? '&sessiontoken=$sessionToken' : '';
    final uri = Uri.parse(
      '$_base/details/json'
      '?place_id=${Uri.encodeComponent(placeId)}'
      '&key=$_apiKey'
      '&fields=geometry'
      '$session',
    );
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        debugPrint(
          'PlacesService.fetchPlaceLatLng error ${res.statusCode}: ${res.body}',
        );
        return null;
      }
      final data = json.decode(res.body) as Map<String, dynamic>;
      final loc =
          (data['result'] as Map<String, dynamic>?)?['geometry']?['location']
              as Map<String, dynamic>?;
      if (loc == null) return null;
      return PlaceLocation(
        lat: (loc['lat'] as num).toDouble(),
        lon: (loc['lng'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('PlacesService.fetchPlaceLatLng exception: $e');
      return null;
    }
  }
}
