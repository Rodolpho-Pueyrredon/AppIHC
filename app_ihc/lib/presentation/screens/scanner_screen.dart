import 'package:app_ihc/core/constants/app_routes.dart';
import 'package:app_ihc/core/di/service_locator.dart';
import 'package:app_ihc/domain/models/price_observation.dart';
import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/models/store.dart';
import 'package:app_ihc/presentation/navigation/detail_edit_args.dart';
import 'package:flutter/material.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _locator = ServiceLocator.instance;
  PriceObservation? _lastObservation;
  bool _isSaving = false;

  Future<void> _simulateScan() async {
    setState(() {
      _isSaving = true;
    });

    final barcode = await _locator.scannerService.scanBarcode();
    final geoPoint = await _locator.geolocationService.getCurrentPosition();

    final now = DateTime.now();
    final observation = PriceObservation(
      product: Product(
        barcode: barcode ?? 'STUB-BARCODE-001',
        name: 'Produto (stub)',
      ),
      store: const Store(
        name: 'Loja (stub)',
      ),
      priceCents: 0,
      observedAt: now,
      latitude: geoPoint?.latitude ?? 0,
      longitude: geoPoint?.longitude ?? 0,
      note: 'Registro inicial criado via scanner stub.',
    );

    final saved = await _locator.priceObservationRepository.saveObservation(
      observation,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _lastObservation = saved;
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Observacao criada com dados iniciais.')),
    );
  }

  void _openHistory() {
    Navigator.pushNamed(context, AppRoutes.history);
  }

  void _openDetail() {
    Navigator.pushNamed(
      context,
      AppRoutes.detailEdit,
      arguments: DetailEditArgs(observation: _lastObservation),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ScannerIntroCard(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _simulateScan,
              child: Text(_isSaving ? 'Salvando...' : 'Simular leitura'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _openHistory,
              child: const Text('Ver historico'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _openDetail,
              child: const Text('Abrir detalhe/edicao'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerIntroCard extends StatelessWidget {
  const _ScannerIntroCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Fluxo inicial do MVP: scanner -> historico -> detalhe/edicao.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
