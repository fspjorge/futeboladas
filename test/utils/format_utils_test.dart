import 'package:flutter_test/flutter_test.dart';
import 'package:futeboladas/utils/format_utils.dart';

void main() {
  group('FormatUtils - formatarPreco', () {
    test('should return Grátis when price is null', () {
      expect(FormatUtils.formatarPreco(null), 'Grátis');
    });

    test('should return Grátis when price is 0', () {
      expect(FormatUtils.formatarPreco(0), 'Grátis');
    });

    test('should return Grátis when price is negative', () {
      expect(FormatUtils.formatarPreco(-5), 'Grátis');
    });

    test('should format positive integer correctly', () {
      expect(FormatUtils.formatarPreco(10), '€ 10.00');
    });

    test('should format positive double correctly', () {
      expect(FormatUtils.formatarPreco(12.5), '€ 12.50');
    });

    test('should format small positive double correctly', () {
      expect(FormatUtils.formatarPreco(0.99), '€ 0.99');
    });
  });
}
