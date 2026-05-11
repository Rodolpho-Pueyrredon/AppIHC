import 'package:app_ihc/core/constants/app_routes.dart';
import 'package:app_ihc/core/constants/screen_origins.dart';
import 'package:app_ihc/core/di/service_locator.dart';
import 'package:app_ihc/presentation/navigation/detail_edit_args.dart';
import 'package:app_ihc/presentation/navigation/history_args.dart';
import 'package:app_ihc/presentation/navigation/scanner_args.dart';
import 'package:app_ihc/presentation/widgets/android_back_to_background.dart';
import 'package:app_ihc/presentation/widgets/scanner_area.dart';
import 'package:app_ihc/presentation/widgets/session_app_bar.dart';
import 'package:flutter/material.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key, this.args});

  final ScannerArgs? args;

  HistoryArgs? _currentArgs() {
    final historyArgs = args?.historyArgs;
    if (historyArgs != null) {
      return historyArgs;
    }

    final session = ServiceLocator.instance.authSession;
    final workGroupId = session.workGroupId;
    if (workGroupId == null || workGroupId.trim().isEmpty) {
      return null;
    }

    return HistoryArgs(
      workGroupId: workGroupId,
      storeName: session.storeName,
      storeAddress: session.storeAddress,
    );
  }

  void _handleDetectedCode(BuildContext context, String code) {
    final currentArgs = _currentArgs();
    final expectedBarcode = args?.expectedBarcode?.trim();
    final returnObservation = args?.returnObservation;

    if (expectedBarcode != null &&
        expectedBarcode.isNotEmpty &&
        returnObservation != null) {
      final matched = code.trim() == expectedBarcode;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.detailEdit,
        arguments: DetailEditArgs(
          observation: returnObservation,
          sourceScreen: ScreenOrigins.screen2,
          workGroupId: currentArgs?.workGroupId,
          storeName: currentArgs?.storeName,
          storeAddress: currentArgs?.storeAddress,
          scanMatched: matched,
          scanErrorMessage: matched
              ? null
              : 'Codigo lido ($code) nao corresponde ao produto selecionado.',
        ),
      );
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.detailEdit,
      arguments: DetailEditArgs(
        scannedCode: code,
        sourceScreen: ScreenOrigins.screen1,
        workGroupId: currentArgs?.workGroupId,
        storeName: currentArgs?.storeName,
        storeAddress: currentArgs?.storeAddress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentArgs = _currentArgs();

    return AndroidBackToBackground(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 112,
          backgroundColor: Colors.red.shade50,
          surfaceTintColor: Colors.red.shade50,
          iconTheme: const IconThemeData(size: 48),
          title: const SessionAppBarTitle(
            child: Text('Scanner', style: TextStyle(fontSize: 24)),
          ),
          actions: [
            IconButton(
              tooltip: 'Historico',
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.history,
                arguments: currentArgs,
              ),
              icon: const Icon(Icons.history, size: 48),
            ),
            const LogoutActionButton(),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ScannerArea(
            onCodeDetected: (code) {
              _handleDetectedCode(context, code);
            },
            onEmptyCode: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nenhum codigo foi lido.')),
              );
            },
            onScanError: (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Falha ao ler codigo. Tente novamente.'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
