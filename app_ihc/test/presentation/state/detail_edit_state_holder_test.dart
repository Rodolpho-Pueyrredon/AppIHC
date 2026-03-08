import 'package:app_ihc/core/constants/screen_origins.dart';
import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/presentation/state/detail_edit_state_holder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DetailEditStateHolder', () {
    test('screen 1 starts filled brand/category as disabled', () {
      final holder = DetailEditStateHolder(
        sourceScreen: ScreenOrigins.screen1,
        initialStoreName: 'Loja',
        initialBrand: 'Brand A',
        initialCategory: 'Category B',
        initialPriceText: '10.00',
      );

      expect(holder.isBrandEnabled, isFalse);
      expect(holder.isCategoryEnabled, isFalse);
      expect(holder.isAnyFieldInEditMode, isFalse);
    });

    test('screen 2 with prefilled brand/category enables edit/save toggle', () {
      final holder = DetailEditStateHolder(
        sourceScreen: ScreenOrigins.screen2,
        initialStoreName: 'Loja',
        initialBrand: 'Brand A',
        initialCategory: 'Category B',
        initialPriceText: '10.00',
      );

      expect(holder.canToggleBrandByButton, isTrue);
      expect(holder.canToggleCategoryByButton, isTrue);
      expect(holder.isBrandEnabled, isFalse);
      expect(holder.isCategoryEnabled, isFalse);

      holder.toggleBrandEditOrSave();
      expect(holder.isBrandEnabled, isTrue);
      expect(holder.isBrandInToggleEditMode, isTrue);
      expect(holder.isAnyFieldInEditMode, isTrue);

      holder.toggleBrandEditOrSave();
      expect(holder.isBrandEnabled, isFalse);
      expect(holder.isBrandInToggleEditMode, isFalse);
      expect(holder.isAnyFieldInEditMode, isFalse);
    });

    test('restoreInitialSnapshot resets edited values and toggles', () {
      final holder = DetailEditStateHolder(
        sourceScreen: ScreenOrigins.screen2,
        initialStoreName: 'Loja',
        initialBrand: 'Brand A',
        initialCategory: 'Category B',
        initialPriceText: '10.00',
      );

      holder.setBrand('Edited Brand');
      holder.setCategory('Edited Category');
      holder.toggleBrandEditOrSave();

      holder.restoreInitialSnapshot();

      expect(holder.brand, 'Brand A');
      expect(holder.category, 'Category B');
      expect(holder.isBrandInToggleEditMode, isFalse);
      expect(holder.isBrandEnabled, isFalse);
    });

    test('applyToProduct trims and nulls empty fields', () {
      final holder = DetailEditStateHolder(
        sourceScreen: ScreenOrigins.screen1,
        initialStoreName: 'Loja',
        initialBrand: '  ',
        initialCategory: '  Mercearia  ',
        initialPriceText: '10.00',
      );
      holder.setBrand('  ');
      holder.setCategory('  Mercearia  ');

      final product = holder.applyToProduct(
        const Product(barcode: '123'),
      );

      expect(product.brand, isNull);
      expect(product.category, 'Mercearia');
    });
  });
}
