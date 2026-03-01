import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OsmSuggestion {
  final String displayName;
  final double lat;
  final double lon;

  OsmSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
  });
}

class OsmService {
  /// Pesquisa locais no OpenStreetMap (Nominatim)
  /// Gratuito e sem necessidade de chave de API.
  Future<List<OsmSuggestion>> search(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      // Usamos coordenadas centrais de Portugal para dar prioridade a resultados locais
      // Removido 'lang': 'pt' porque o Photon só suporta en, de, fr, it.
      final queryParams = {
        'q': query,
        'limit': '15',
        'lat': '39.5',
        'lon': '-8.0',
        'location_bias_scale': '0.5',
      };

      final uri = Uri.https('photon.komoot.io', '/api', queryParams);
      debugPrint('Photon Request: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Photon Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> features = data['features'] ?? [];
        debugPrint('Photon Found ${features.length} results');

        return features.map((feat) {
          final props = feat['properties'] ?? {};
          final geom = feat['geometry'] ?? {};
          final coords = geom['coordinates'] as List<dynamic>?;

          // Construir uma descrição legível
          final String name = props['name'] ?? '';
          final String city =
              props['city'] ??
              props['town'] ??
              props['village'] ??
              props['state'] ??
              '';
          final String street = props['street'] ?? '';
          final String country = props['country'] ?? '';

          final List<String> parts = [];
          if (name.isNotEmpty) parts.add(name);
          if (street.isNotEmpty) parts.add(street);
          if (city.isNotEmpty) parts.add(city);
          if (country.isNotEmpty) parts.add(country);

          return OsmSuggestion(
            displayName: parts.join(', '),
            lat: coords != null && coords.length > 1
                ? (coords[1] as num).toDouble()
                : 0.0,
            lon: coords != null && coords.isNotEmpty
                ? (coords[0] as num).toDouble()
                : 0.0,
          );
        }).toList();
      } else {
        debugPrint('Photon Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Photon Exception: $e');
    }
    return [];
  }
}
