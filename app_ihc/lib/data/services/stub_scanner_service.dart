import 'package:app_ihc/domain/services/scanner_service_contract.dart';

class StubScannerService implements ScannerServiceContract {
  @override
  Future<String?> scanBarcode() async {
    // Stub temporario ate integrar plugin real de scanner.
    return 'STUB-BARCODE-001';
  }
}
