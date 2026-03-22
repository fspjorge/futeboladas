import 'package:flutter_test/flutter_test.dart';
import 'package:futeboladas/models/filter_mode.dart';

void main() {
  group('FilterMode Enum', () {
    test('contains expected values', () {
      expect(FilterMode.values.length, 4);
      expect(FilterMode.all.name, 'all');
      expect(FilterMode.mine.name, 'mine');
      expect(FilterMode.attending.name, 'attending');
      expect(FilterMode.free.name, 'free');
    });
  });
}
