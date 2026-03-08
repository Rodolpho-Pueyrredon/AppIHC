import 'package:app_ihc/core/constants/app_routes.dart';
import 'package:app_ihc/core/constants/screen_origins.dart';
import 'package:app_ihc/core/di/service_locator.dart';
import 'package:app_ihc/presentation/navigation/detail_edit_args.dart';
import 'package:app_ihc/presentation/widgets/scanner_area.dart';
import 'package:flutter/material.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scannerService = ServiceLocator.instance.scannerService;

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
          scannerService: scannerService,
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
        ),
      ),
    );
  }
}
