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
        automaticallyImplyLeading: false,
        toolbarHeight: 112,
        backgroundColor: Colors.red.shade50,
        surfaceTintColor: Colors.red.shade50,
        iconTheme: const IconThemeData(size: 48),
        title: const Text('Scanner', style: TextStyle(fontSize: 24)),
        actions: [
          IconButton(
            tooltip: 'Historico',
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              AppRoutes.history,
            ),
            icon: const Icon(Icons.history, size: 48),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ScannerArea(
          onCodeDetected: (code) {
            Navigator.pushReplacementNamed(
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




