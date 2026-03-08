import 'package:app_ihc/core/constants/app_routes.dart';
import 'package:app_ihc/core/constants/screen_origins.dart';
import 'package:app_ihc/core/di/service_locator.dart';
import 'package:app_ihc/core/utils/price_parser.dart';
import 'package:app_ihc/domain/models/price_observation.dart';
import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/models/store.dart';
import 'package:app_ihc/presentation/navigation/detail_edit_args.dart';
import 'package:app_ihc/presentation/state/detail_edit_state_holder.dart';
import 'package:flutter/material.dart';

class DetailEditScreen extends StatefulWidget {
  const DetailEditScreen({
    super.key,
    required this.args,
  });

  final DetailEditArgs args;

  @override
  State<DetailEditScreen> createState() => _DetailEditScreenState();
}

class _DetailEditScreenState extends State<DetailEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ServiceLocator.instance.priceObservationRepository;
  final _lookupUseCase = ServiceLocator.instance.lookupProductByBarcodeUseCase;
  final _geolocationService = ServiceLocator.instance.geolocationService;

  late final TextEditingController _storeNameController;
  late final TextEditingController _brandController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;

  late PriceObservation _baseObservation;
  DetailEditStateHolder? _stateHolder;
  bool _isSaving = false;
  bool _isLoadingProductInfo = false;
  String? _sourceScreen;

  @override
  void initState() {
    super.initState();
    _sourceScreen = widget.args.sourceScreen;
    _baseObservation = _initialObservation();

    _storeNameController = TextEditingController(
      text: _baseObservation.store.name,
    );
    _brandController = TextEditingController(
      text: _baseObservation.product.brand ?? '',
    );
    _categoryController = TextEditingController(
      text: _baseObservation.product.category ?? '',
    );
    _priceController = TextEditingController(
      text: _baseObservation.price.toStringAsFixed(2),
    );

    _stateHolder = DetailEditStateHolder(
      sourceScreen: _sourceScreen,
      initialStoreName: _storeNameController.text,
      initialBrand: _brandController.text,
      initialCategory: _categoryController.text,
      initialPriceText: _priceController.text,
    );

    if (_shouldLookupProduct()) {
      _lookupProductData();
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  PriceObservation _initialObservation() {
    final now = DateTime.now();
    final observationFromArgs = widget.args.observation;
    if (observationFromArgs != null) {
      return observationFromArgs;
    }

    return PriceObservation(
      product: Product(
        barcode: widget.args.scannedCode ?? 'MANUAL-BARCODE',
        name: '',
      ),
      store: const Store(name: ''),
      priceCents: 0,
      latitude: 0,
      longitude: 0,
      observedAt: now,
    );
  }

  bool _shouldLookupProduct() {
    return _sourceScreen == ScreenOrigins.screen1 &&
        widget.args.scannedCode != null &&
        widget.args.scannedCode!.trim().isNotEmpty;
  }

  Future<void> _lookupProductData() async {
    setState(() {
      _isLoadingProductInfo = true;
    });

    try {
      final lookedUp = await _lookupUseCase(_baseObservation.product.barcode);
      if (!mounted) {
        return;
      }

      _baseObservation = _baseObservation.copyWith(product: lookedUp);
      _brandController.text = lookedUp.brand ?? '';
      _categoryController.text = lookedUp.category ?? '';

      _stateHolder = DetailEditStateHolder(
        sourceScreen: _sourceScreen,
        initialStoreName: _storeNameController.text,
        initialBrand: _brandController.text,
        initialCategory: _categoryController.text,
        initialPriceText: _priceController.text,
      );

      if ((lookedUp.brand ?? '').trim().isEmpty &&
          (lookedUp.category ?? '').trim().isEmpty) {
        _showFeedback('Nao foi possivel completar lookup de API. Preencha manualmente.');
      }
    } catch (_) {
      if (mounted) {
        _showFeedback('Erro ao consultar API de produto. Preencha manualmente.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProductInfo = false;
        });
      }
    }
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) {
      _showFeedback('Revise os campos obrigatorios antes de confirmar.');
      return;
    }

    final state = _stateHolder!;
    if (state.isAnyFieldInEditMode) {
      return;
    }

    state.setStoreName(_storeNameController.text.trim());
    state.setBrand(_brandController.text.trim());
    state.setCategory(_categoryController.text.trim());
    state.setPriceText(_priceController.text.trim());

    final priceCents = parsePriceToCents(state.priceText);
    if (priceCents == null) {
      _showFeedback('Preco invalido. Informe valor numerico maior que zero.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now().toUtc();
      final geolocation = await _geolocationService.getCurrentPosition();
      final productWithFallbackBarcode = state
          .applyToProduct(_baseObservation.product)
          .copyWith(
            barcode: _baseObservation.product.barcode.trim().isEmpty
                ? 'MANUAL-BARCODE'
                : _baseObservation.product.barcode,
          );

      final newObservation = PriceObservation(
        product: productWithFallbackBarcode,
        store: _baseObservation.store.copyWith(name: state.storeName),
        priceCents: priceCents,
        latitude: geolocation?.latitude ?? _baseObservation.latitude,
        longitude: geolocation?.longitude ?? _baseObservation.longitude,
        observedAt: now,
        note: _baseObservation.note,
        createdAt: now,
      );

      await _repository.saveObservation(newObservation);
    } catch (_) {
      if (mounted) {
        _showFeedback('Erro ao salvar no banco local. Tente novamente.');
        setState(() {
          _isSaving = false;
        });
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    _showFeedback('Observacao salva com sucesso.');
    _goBackToOrigin();
  }

  void _cancel() {
    final state = _stateHolder!;

    if (state.isAnyFieldInEditMode) {
      // Durante edicao de brand/category: reset local sem navegar.
      state.restoreInitialSnapshot();
      _storeNameController.text = state.storeName;
      _brandController.text = state.brand;
      _categoryController.text = state.category;
      _priceController.text = state.priceText;
      setState(() {});
      return;
    }

    _goBackToOrigin();
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _goBackToOrigin() {
    final route = _sourceScreen == ScreenOrigins.screen2
        ? AppRoutes.history
        : AppRoutes.scanner;

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacementNamed(context, route);
  }

  void _onBrandEditOrSave() {
    final state = _stateHolder!;
    state.setBrand(_brandController.text);
    state.toggleBrandEditOrSave();
    setState(() {});
  }

  void _onCategoryEditOrSave() {
    final state = _stateHolder!;
    state.setCategory(_categoryController.text);
    state.toggleCategoryEditOrSave();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _stateHolder!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe / Edicao'),
        actions: [
          IconButton(
            tooltip: 'Historico',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: _isLoadingProductInfo
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProductInfoSection(
                      name: _baseObservation.product.name,
                      barcode: _baseObservation.product.barcode,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _storeNameController,
                      decoration:
                          const InputDecoration(labelText: 'Estabelecimento'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o estabelecimento.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _EditableFieldRow(
                      label: 'Brand',
                      controller: _brandController,
                      enabled: state.isBrandEnabled,
                      sideButtonLabel:
                          state.canToggleBrandByButton
                              ? (state.isBrandInToggleEditMode ? 'save' : 'edit')
                              : null,
                      onSideButtonPressed:
                          state.canToggleBrandByButton
                              ? _onBrandEditOrSave
                              : null,
                    ),
                    const SizedBox(height: 12),
                    _EditableFieldRow(
                      label: 'Category',
                      controller: _categoryController,
                      enabled: state.isCategoryEnabled,
                      sideButtonLabel:
                          state.canToggleCategoryByButton
                              ? (state.isCategoryInToggleEditMode
                                  ? 'save'
                                  : 'edit')
                              : null,
                      onSideButtonPressed:
                          state.canToggleCategoryByButton
                              ? _onCategoryEditOrSave
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Preco'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (parsePriceToCents(value ?? '') == null) {
                          return 'Informe um preco valido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (!state.isAnyFieldInEditMode)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _confirm,
                              child: Text(_isSaving ? 'Salvando...' : 'Confirmar'),
                            ),
                          ),
                        if (!state.isAnyFieldInEditMode) const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _cancel,
                            child: const Text('Cancelar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ProductInfoSection extends StatelessWidget {
  const _ProductInfoSection({
    required this.name,
    required this.barcode,
  });

  final String? name;
  final String barcode;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name == null || name!.trim().isEmpty ? 'Produto' : name!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text('Codigo: $barcode'),
          ],
        ),
      ),
    );
  }
}

class _EditableFieldRow extends StatelessWidget {
  const _EditableFieldRow({
    required this.label,
    required this.controller,
    required this.enabled,
    this.sideButtonLabel,
    this.onSideButtonPressed,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? sideButtonLabel;
  final VoidCallback? onSideButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            decoration: InputDecoration(labelText: label),
          ),
        ),
        if (sideButtonLabel != null) ...[
          const SizedBox(width: 8),
          SizedBox(
            height: 56,
            child: TextButton(
              onPressed: onSideButtonPressed,
              child: Text(sideButtonLabel!),
            ),
          ),
        ],
      ],
    );
  }
}
