import 'package:app_ihc/core/utils/price_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePriceToCents', () {
    test('converts formatted and decimal-like inputs to cents', () {
      expect(parsePriceToCents('10.50'), 1050);
      expect(parsePriceToCents('10,50'), 1050);
      expect(parsePriceToCents('R\$ 10,50'), 1050);
      expect(parsePriceToCents('001'), 1);
    });

    test('returns null for invalid or non-positive values', () {
      expect(parsePriceToCents(''), isNull);
      expect(parsePriceToCents('abc'), isNull);
      expect(parsePriceToCents('0'), isNull);
      expect(parsePriceToCents('R\$ 0,00'), isNull);
    });
  });

  group('price formatting', () {
    test('formats cents as brazilian currency text', () {
      expect(formatPriceFromCents(0), 'R\$ 0,00');
      expect(formatPriceFromCents(1), 'R\$ 0,01');
      expect(formatPriceFromCents(1050), 'R\$ 10,50');
    });

    test('formats raw typed digits from cents to the left', () {
      expect(formatPriceInput('1'), 'R\$ 0,01');
      expect(formatPriceInput('12'), 'R\$ 0,12');
      expect(formatPriceInput('123'), 'R\$ 1,23');
      expect(formatPriceInput('1234'), 'R\$ 12,34');
    });
  });
}
