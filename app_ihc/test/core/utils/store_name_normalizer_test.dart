import 'package:app_ihc/core/utils/store_name_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeStoreName removes accents, trims and lowers text', () {
    final normalized = normalizeStoreName('  São   JOÃO  Mercado  ');
    expect(normalized, 'sao joao mercado');
  });
}
