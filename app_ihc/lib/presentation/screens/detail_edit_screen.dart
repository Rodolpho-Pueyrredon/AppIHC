import 'package:app_ihc/core/constants/app_routes.dart';
import 'package:app_ihc/core/constants/screen_origins.dart';
import 'package:app_ihc/core/di/service_locator.dart';
import 'package:app_ihc/core/utils/price_parser.dart';
import 'package:app_ihc/domain/models/price_observation.dart';
import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/models/store.dart';
import 'package:app_ihc/presentation/navigation/detail_edit_args.dart';
import 'package:app_ihc/presentation/navigation/history_args.dart';
import 'package:app_ihc/presentation/navigation/scanner_args.dart';
import 'package:app_ihc/presentation/state/detail_edit_state_holder.dart';
import 'package:app_ihc/presentation/widgets/android_back_to_background.dart';
import 'package:app_ihc/presentation/widgets/session_app_bar.dart';
import 'package:flutter/material.dart';

class DetailEditScreen extends StatefulWidget {
  const DetailEditScreen({super.key, required this.args});

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
  bool _isFormattingPrice = false;
  bool _isPriceUnlocked = false;
  bool _showMatchFeedback = false;
  String? _sourceScreen;

  HistoryArgs? get _currentHistoryArgs {
    final workGroupId =
        widget.args.workGroupId ??
        ServiceLocator.instance.authSession.workGroupId;
    if (workGroupId == null || workGroupId.trim().isEmpty) {
      return null;
    }

    return HistoryArgs(
      workGroupId: workGroupId,
      storeName:
          widget.args.storeName ??
          ServiceLocator.instance.authSession.storeName,
      storeAddress:
          widget.args.storeAddress ??
          ServiceLocator.instance.authSession.storeAddress,
    );
  }

  @override
  void initState() {
    super.initState();
    _sourceScreen = widget.args.sourceScreen;
    _isPriceUnlocked = widget.args.scanMatched == true;
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
      text: formatPriceFromCents(_baseObservation.priceCents),
    );
    _priceController.addListener(_onPriceChanged);

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

    _showScanFeedbackFromArgs();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _priceController.removeListener(_onPriceChanged);
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
        _showFeedback(
          'Produto nao encontrado no banco local. Preencha manualmente.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showFeedback(
          'Erro ao consultar o banco local de produtos. Preencha manualmente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProductInfo = false;
        });
      }
    }
  }

  void _onPriceChanged() {
    if (_isFormattingPrice) {
      return;
    }

    final formatted = formatPriceInput(_priceController.text);
    if (_priceController.text == formatted) {
      return;
    }

    _isFormattingPrice = true;
    _priceController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormattingPrice = false;
  }

  Future<void> _confirm() async {
    if (!_isPriceUnlocked) {
      _showFeedback(
        'Leia o codigo de barras correto antes de informar o preco.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showFeedback('Revise os campos obrigatorios antes de confirmar.');
      return;
    }

    final state = _stateHolder!;
    state.setStoreName(_storeNameController.text.trim());
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
      final productWithFallbackBarcode = state
          .applyToProduct(_baseObservation.product)
          .copyWith(
            barcode: _baseObservation.product.barcode.trim().isEmpty
                ? 'MANUAL-BARCODE'
                : _baseObservation.product.barcode,
          );
      final store = _baseObservation.store.copyWith(name: state.storeName);

      final isExistingObservation = _baseObservation.id != null;
      final isPriceChanged = priceCents != _baseObservation.priceCents;

      if (isExistingObservation && !isPriceChanged) {
        final updatedObservation = _baseObservation.copyWith(
          product: productWithFallbackBarcode,
          store: store,
        );
        await _repository.updateObservation(updatedObservation);
      } else {
        final now = DateTime.now().toUtc();
        final geolocation = await _geolocationService.getCurrentPosition();
        final newObservation = PriceObservation(
          product: productWithFallbackBarcode,
          store: store,
          priceCents: priceCents,
          latitude: geolocation?.latitude ?? _baseObservation.latitude,
          longitude: geolocation?.longitude ?? _baseObservation.longitude,
          observedAt: now,
          note: _baseObservation.note,
          createdAt: now,
        );
        await _repository.saveObservation(newObservation);
      }
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

    _showFeedback('Preco salvo com sucesso.');
    _goBackToOrigin();
  }

  void _cancel() {
    _goBackToOrigin();
  }

  Future<void> _deleteObservation() async {
    final observationId = _baseObservation.id;
    if (observationId == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.deleteObservation(observationId);
    } catch (_) {
      if (mounted) {
        _showFeedback('Erro ao deletar observacao.');
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

    _showFeedback('Observacao deletada.');
    _goBackToOrigin();
  }

  void _showFeedback(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  void _goBackToOrigin() {
    final route = _sourceScreen == ScreenOrigins.screen2
        ? AppRoutes.history
        : AppRoutes.scanner;

    Navigator.pushReplacementNamed(
      context,
      route,
      arguments: _currentHistoryArgs,
    );
  }

  void _goToScanner() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.scanner,
      arguments: ScannerArgs(
        historyArgs: _currentHistoryArgs,
        expectedBarcode: _baseObservation.product.barcode,
        returnObservation: _baseObservation.copyWith(
          product: _stateHolder?.applyToProduct(_baseObservation.product),
          store: _baseObservation.store.copyWith(
            name: _storeNameController.text.trim(),
          ),
        ),
      ),
    );
  }

  void _showScanFeedbackFromArgs() {
    if (widget.args.scanMatched == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _showMatchFeedback = true;
        });

        Future<void>.delayed(const Duration(milliseconds: 1400), () {
          if (!mounted) {
            return;
          }
          setState(() {
            _showMatchFeedback = false;
          });
        });
      });
      return;
    }

    final errorMessage = widget.args.scanErrorMessage;
    if (errorMessage == null || errorMessage.trim().isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFFD6D6),
            title: Row(
              children: [
                const Expanded(child: Text('Codigo incorreto')),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            content: Text(errorMessage),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AndroidBackToBackground(
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 112,
              backgroundColor: Colors.red.shade50,
              surfaceTintColor: Colors.red.shade50,
              iconTheme: const IconThemeData(size: 48),
              title: const SessionAppBarTitle(
                child: Text('Detalhe / Edicao', style: TextStyle(fontSize: 24)),
              ),
              actions: [
                TextButton.icon(
                  onPressed: _goToScanner,
                  icon: const Icon(Icons.qr_code_scanner, size: 48),
                  label: const Text('Ler', style: TextStyle(fontSize: 24)),
                ),
                IconButton(
                  tooltip: 'Historico',
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.history,
                    arguments: _currentHistoryArgs,
                  ),
                  icon: const Icon(Icons.history, size: 48),
                ),
                const LogoutActionButton(),
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
                            name:
                                _baseObservation.product.name ??
                                _baseObservation.product.category,
                            barcode: _baseObservation.product.barcode,
                          ),
                          const SizedBox(height: 16),
                          _ReadOnlyInfoField(
                            label: 'Estabelecimento',
                            value: _storeNameController.text,
                          ),
                          const SizedBox(height: 12),
                          _ReadOnlyInfoField(
                            label: 'Brand',
                            value: _brandController.text,
                          ),
                          const SizedBox(height: 12),
                          _ReadOnlyInfoField(
                            label: 'Category',
                            value: _categoryController.text,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _priceController,
                            enabled: _isPriceUnlocked,
                            decoration: const InputDecoration(
                              labelText: 'Preco',
                            ),
                            keyboardType: TextInputType.number,
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
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving || !_isPriceUnlocked
                                      ? null
                                      : _confirm,
                                  child: Text(
                                    _isSaving ? 'Salvando...' : 'Confirmar',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _cancel,
                                  child: const Text('Cancelar'),
                                ),
                              ),
                            ],
                          ),
                          if (_baseObservation.id != null)
                            const SizedBox(height: 10),
                          if (_baseObservation.id != null)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _isSaving
                                    ? null
                                    : _deleteObservation,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                ),
                                child: const Text('Deletar'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeInOut,
              opacity: _showMatchFeedback ? 1 : 0,
              child: ColoredBox(
                color: Colors.green.withAlpha(34),
                child: Center(
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutBack,
                    scale: _showMatchFeedback ? 1 : 0.82,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(235),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductInfoSection extends StatelessWidget {
  const _ProductInfoSection({required this.name, required this.barcode});

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

class _ReadOnlyInfoField extends StatelessWidget {
  const _ReadOnlyInfoField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();

    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(
        displayValue,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
