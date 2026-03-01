import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:futeboladas/services/osm_service.dart';
import '../helpers/mockito_helper.mocks.dart';

void main() {
  late OsmService osmService;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    osmService = OsmService(client: mockClient);
  });

  group('OsmService - search', () {
    test('should return empty list if query is empty', () async {
      final results = await osmService.search('');
      expect(results, isEmpty);
      verifyNever(mockClient.get(any, headers: anyNamed('headers')));
    });

    test('should return suggestions on successful response', () async {
      final mockResponse = {
        'features': [
          {
            'properties': {
              'name': 'Estádio da Luz',
              'city': 'Lisboa',
              'country': 'Portugal',
            },
            'geometry': {
              'coordinates': [-9.1846, 38.7527],
            },
          },
        ],
      };

      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final results = await osmService.search('Luz');

      expect(results, isNotEmpty);
      expect(results[0].displayName, contains('Estádio da Luz'));
      expect(results[0].lat, 38.7527);
      expect(results[0].lon, -9.1846);
    });

    test('should return empty list on error response', () async {
      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('Error', 500));

      final results = await osmService.search('Luz');
      expect(results, isEmpty);
    });

    test('should return empty list on exception', () async {
      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenThrow(Exception('Network error'));

      final results = await osmService.search('Luz');
      expect(results, isEmpty);
    });
  });
}
