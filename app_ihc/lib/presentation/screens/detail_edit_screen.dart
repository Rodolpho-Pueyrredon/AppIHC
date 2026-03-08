import 'package:app_ihc/core/di/service_locator.dart';
import 'package:app_ihc/domain/models/price_observation.dart';
import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/models/store.dart';
import 'package:app_ihc/presentation/navigation/detail_edit_args.dart';
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

  late final TextEditingController _productNameController;
  late final TextEditingController _storeNameController;
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;

  late final PriceObservation _baseObservation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _baseObservation = widget.args.observation ??
        PriceObservation(
          product: const Product(barcode: 'MANUAL-BARCODE', name: ''),
          store: const Store(name: ''),
          priceCents: 0,
          latitude: 0,
          longitude: 0,
          observedAt: now,
        );

    _productNameController = TextEditingController(
      text: _baseObservation.product.name ?? '',
    );
    _storeNameController = TextEditingController(
      text: _baseObservation.store.name,
    );
    _priceController = TextEditingController(
      text: _baseObservation.price.toStringAsFixed(2),
    );
    _noteController = TextEditingController(
      text: _baseObservation.note ?? '',
    );
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _storeNameController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updated = _baseObservation.copyWith(
      product: _baseObservation.product.copyWith(
        barcode: _baseObservation.product.barcode.trim().isEmpty
            ? 'MANUAL-BARCODE'
            : _baseObservation.product.barcode,
        name: _productNameController.text.trim(),
      ),
      store: _baseObservation.store.copyWith(
        name: _storeNameController.text.trim(),
      ),
      priceCents:
          ((double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0) *
                  100)
              .round(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (updated.id == null) {
      await _repository.saveObservation(updated);
    } else {
      await _repository.updateObservation(updated);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Observacao salva.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe / Edicao')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(labelText: 'Produto'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o produto.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _storeNameController,
                decoration: const InputDecoration(labelText: 'Loja'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a loja.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Preco'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Observacoes'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? 'Salvando...' : 'Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
