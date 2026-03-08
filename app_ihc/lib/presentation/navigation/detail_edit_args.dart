import 'package:app_ihc/domain/models/price_observation.dart';

class DetailEditArgs {
  const DetailEditArgs({
    this.observation,
    this.scannedCode,
    this.sourceScreen,
  });

  final PriceObservation? observation;
  final String? scannedCode;
  final String? sourceScreen;
}
