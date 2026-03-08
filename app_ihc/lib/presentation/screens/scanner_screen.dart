import 'package:app_ihc/core/constants/app_routes.dart';
import 'package:app_ihc/core/constants/screen_origins.dart';
import 'package:app_ihc/presentation/navigation/detail_edit_args.dart';
import 'package:app_ihc/presentation/widgets/scanner_area.dart';
import 'package:flutter/material.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner'),
        actions: [
          IconButton(
            tooltip: 'Historico',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ScannerArea(
          onCodeDetected: (code) {
            Navigator.pushNamed(
              context,
              AppRoutes.detailEdit,
              arguments: DetailEditArgs(
                scannedCode: code,
                sourceScreen: ScreenOrigins.screen1,
              ),
            );
          },
          onEmptyCode: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nenhum codigo foi lido.')),
            );
          },
          onScanError: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Falha ao ler codigo. Tente novamente.')),
            );
          },
        ),
      ),
    );
  }
}
