import 'package:app_ihc/domain/models/price_observation.dart';
import 'package:app_ihc/presentation/navigation/history_args.dart';

class ScannerArgs {
  const ScannerArgs({
    this.historyArgs,
    this.expectedBarcode,
    this.returnObservation,
  });

  final HistoryArgs? historyArgs;
  final String? expectedBarcode;
  final PriceObservation? returnObservation;
}
