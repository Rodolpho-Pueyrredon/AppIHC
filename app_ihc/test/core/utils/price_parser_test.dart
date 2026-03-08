import 'package:app_ihc/core/utils/price_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePriceToCents', () {
    test('converts decimal and comma formats', () {
      expect(parsePriceToCents('10.50'), 1050);
      expect(parsePriceToCents('10,50'), 1050);
    });

    test('returns null for invalid or non-positive values', () {
      expect(parsePriceToCents(''), isNull);
      expect(parsePriceToCents('abc'), isNull);
      expect(parsePriceToCents('-1.0'), isNull);
      expect(parsePriceToCents('0'), isNull);
    });
  });
}
