import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceSuggestion {
  final String placeId;
  final String description;
  PlaceSuggestion({required this.placeId, required this.description});
}

class PlaceLocation {
  final double lat;
  final double lon;
  PlaceLocation({required this.lat, required this.lon});
}

class PlacesService {
  // Provide this at build time: --dart-define=PLACES_API_KEY=YOUR_KEY
  static const String _apiKey = String.fromEnvironment('PLACES_API_KEY', defaultValue: '');
  static const String _base = 'https://maps.googleapis.com/maps/api/place';

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<List<PlaceSuggestion>> autocomplete(String query, {String? sessionToken, String language = 'pt', String country = 'pt'}) async {
    if (!isConfigured) return [];
    final uri = Uri.parse(
      '$_base/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$_apiKey&language=$language&components=country:$country${sessionToken != null ? '&sessiontoken=$sessionToken' : ''}',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final data = json.decode(res.body) as Map<String, dynamic>;
    final preds = (data['predictions'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map((p) => PlaceSuggestion(
              placeId: p['place_id'] as String,
              description: p['description'] as String,
            ))
        .toList();
    return preds;
  }

  Future<PlaceLocation?> fetchPlaceLatLng(String placeId, {String? sessionToken}) async {
    if (!isConfigured) return null;
    final uri = Uri.parse(
      '$_base/details/json?place_id=${Uri.encodeComponent(placeId)}&key=$_apiKey&fields=geometry${sessionToken != null ? '&sessiontoken=$sessionToken' : ''}',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final data = json.decode(res.body) as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>?;
    final geom = result?['geometry'] as Map<String, dynamic>?;
    final loc = geom?['location'] as Map<String, dynamic>?;
    if (loc == null) return null;
    return PlaceLocation(lat: (loc['lat'] as num).toDouble(), lon: (loc['lng'] as num).toDouble());
  }
}

