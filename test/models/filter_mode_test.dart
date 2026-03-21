import 'package:flutter_test/flutter_test.dart';
import 'package:futeboladas/models/filter_mode.dart';

void main() {
  group('FilterMode Enum', () {
    test('contains expected values', () {
      expect(FilterMode.values.length, 4);
      expect(FilterMode.todos.name, 'todos');
      expect(FilterMode.meus.name, 'meus');
      expect(FilterMode.participo.name, 'participo');
      expect(FilterMode.gratuitos.name, 'gratuitos');
    });
  });
}
