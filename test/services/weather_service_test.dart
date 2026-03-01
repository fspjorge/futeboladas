import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:futeboladas/services/weather_service.dart';
import '../helpers/mockito_helper.mocks.dart';

void main() {
  late WeatherService weatherService;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    weatherService = WeatherService(client: mockClient);
  });

  group('WeatherService - getWeather', () {
    test('should return data on successful response', () async {
      final mockResponse = {
        'main': {'temp': 20},
        'weather': [
          {'description': 'céu limpo'},
        ],
      };

      when(
        mockClient.get(any),
      ).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await weatherService.getWeather(38.7, -9.1);

      expect(result, isNotNull);
      expect(result!['main']['temp'], 20);
    });

    test('should return null on error response', () async {
      when(
        mockClient.get(any),
      ).thenAnswer((_) async => http.Response('Error', 404));

      final result = await weatherService.getWeather(38.7, -9.1);
      expect(result, isNull);
    });
  });

  group('WeatherService - getForecastAt', () {
    test('should return parsed forecast safely', () async {
      final now = DateTime.now();
      final mockResponse = {
        'list': [
          {
            'dt': now.millisecondsSinceEpoch ~/ 1000,
            'main': {'temp': 18.2},
            'weather': [
              {'description': 'nuvens dispersas'},
            ],
            'sys': {'pod': 'd'},
          },
        ],
      };

      when(
        mockClient.get(any),
      ).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await weatherService.getForecastAt(38.7, -9.1, now);

      expect(result, isNotNull);
      expect(result!['temp'], 18);
      expect(result['desc'], 'nuvens dispersas');
    });
  });
}
