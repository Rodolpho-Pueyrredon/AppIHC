import 'package:app_ihc/core/constants/screen_origins.dart';
import 'package:app_ihc/domain/models/product.dart';

class DetailEditSnapshot {
  const DetailEditSnapshot({
    required this.storeName,
    required this.brand,
    required this.category,
    required this.priceText,
    required this.brandEnabled,
    required this.categoryEnabled,
    required this.brandEditingByToggle,
    required this.categoryEditingByToggle,
  });

  final String storeName;
  final String brand;
  final String category;
  final String priceText;
  final bool brandEnabled;
  final bool categoryEnabled;
  final bool brandEditingByToggle;
  final bool categoryEditingByToggle;
}

class DetailEditStateHolder {
  DetailEditStateHolder({
    required this.sourceScreen,
    required this.initialStoreName,
    required this.initialBrand,
    required this.initialCategory,
    required this.initialPriceText,
  })  : _storeName = initialStoreName,
        _brand = initialBrand,
        _category = initialCategory,
        _priceText = initialPriceText {
    _initEditability();
    _initialSnapshot = currentSnapshot();
  }

  final String? sourceScreen;

  final String initialStoreName;
  final String initialBrand;
  final String initialCategory;
  final String initialPriceText;

  late final DetailEditSnapshot _initialSnapshot;

  late String _storeName;
  late String _brand;
  late String _category;
  late String _priceText;

  bool _brandEnabled = false;
  bool _categoryEnabled = false;
  bool _brandEditingByToggle = false;
  bool _categoryEditingByToggle = false;

  String get storeName => _storeName;
  String get brand => _brand;
  String get category => _category;
  String get priceText => _priceText;
  bool get isBrandEnabled => _brandEnabled;
  bool get isCategoryEnabled => _categoryEnabled;
  bool get isBrandInToggleEditMode => _brandEditingByToggle;
  bool get isCategoryInToggleEditMode => _categoryEditingByToggle;

  bool get isFromScreen1 => sourceScreen == ScreenOrigins.screen1;
  bool get isFromScreen2 => sourceScreen == ScreenOrigins.screen2;

  bool get isAnyFieldInEditMode =>
      _brandEditingByToggle || _categoryEditingByToggle;

  bool get canToggleBrandByButton => isFromScreen2 && initialBrand.isNotEmpty;
  bool get canToggleCategoryByButton =>
      isFromScreen2 && initialCategory.isNotEmpty;

  void setStoreName(String value) => _storeName = value;
  void setBrand(String value) => _brand = value;
  void setCategory(String value) => _category = value;
  void setPriceText(String value) => _priceText = value;

  void toggleBrandEditOrSave() {
    if (!canToggleBrandByButton) {
      return;
    }

    if (_brandEditingByToggle) {
      _brandEditingByToggle = false;
      _brandEnabled = false;
      return;
    }

    _brandEditingByToggle = true;
    _brandEnabled = true;
  }

  void toggleCategoryEditOrSave() {
    if (!canToggleCategoryByButton) {
      return;
    }

    if (_categoryEditingByToggle) {
      _categoryEditingByToggle = false;
      _categoryEnabled = false;
      return;
    }

    _categoryEditingByToggle = true;
    _categoryEnabled = true;
  }

  DetailEditSnapshot currentSnapshot() {
    return DetailEditSnapshot(
      storeName: _storeName,
      brand: _brand,
      category: _category,
      priceText: _priceText,
      brandEnabled: _brandEnabled,
      categoryEnabled: _categoryEnabled,
      brandEditingByToggle: _brandEditingByToggle,
      categoryEditingByToggle: _categoryEditingByToggle,
    );
  }

  void restoreInitialSnapshot() {
    _storeName = _initialSnapshot.storeName;
    _brand = _initialSnapshot.brand;
    _category = _initialSnapshot.category;
    _priceText = _initialSnapshot.priceText;
    _brandEnabled = _initialSnapshot.brandEnabled;
    _categoryEnabled = _initialSnapshot.categoryEnabled;
    _brandEditingByToggle = _initialSnapshot.brandEditingByToggle;
    _categoryEditingByToggle = _initialSnapshot.categoryEditingByToggle;
  }

  Product applyToProduct(Product baseProduct) {
    return baseProduct.copyWith(
      brand: _brand.trim().isEmpty ? null : _brand.trim(),
      category: _category.trim().isEmpty ? null : _category.trim(),
    );
  }

  void _initEditability() {
    if (isFromScreen1) {
      // Tela 1: se vier vazio habilita preenchimento manual; se preenchido, bloqueia.
      _brandEnabled = initialBrand.isEmpty;
      _categoryEnabled = initialCategory.isEmpty;
      return;
    }

    // Tela 2: se vier preenchido, inicia bloqueado; se vazio, inicia editavel.
    _brandEnabled = initialBrand.isEmpty;
    _categoryEnabled = initialCategory.isEmpty;
  }
}
