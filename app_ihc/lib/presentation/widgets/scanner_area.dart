import 'package:app_ihc/domain/services/scanner_service_contract.dart';
import 'package:flutter/material.dart';

class ScannerArea extends StatefulWidget {
  const ScannerArea({
    super.key,
    required this.scannerService,
    required this.onCodeDetected,
    this.onScanError,
    this.onEmptyCode,
  });

  final ScannerServiceContract scannerService;
  final ValueChanged<String> onCodeDetected;
  final ValueChanged<String>? onScanError;
  final VoidCallback? onEmptyCode;

  @override
  State<ScannerArea> createState() => _ScannerAreaState();
}

class _ScannerAreaState extends State<ScannerArea> {
  bool _isReading = false;

  Future<void> _readCode() async {
    setState(() {
      _isReading = true;
    });

    try {
      final code = await widget.scannerService.scanBarcode();
      if (!mounted) {
        return;
      }

      setState(() {
        _isReading = false;
      });

      if (code == null || code.trim().isEmpty) {
        widget.onEmptyCode?.call();
        return;
      }

      widget.onCodeDetected(code);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isReading = false;
      });

      widget.onScanError?.call(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 260,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Area do scanner (stub/mocavel)'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isReading ? null : _readCode,
              child: Text(_isReading ? 'Lendo...' : 'Ler barcode / QR code'),
            ),
          ],
        ),
      ),
    );
  }
}
