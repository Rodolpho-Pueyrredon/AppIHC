import 'package:app_ihc/domain/models/price_observation.dart';

class DetailEditArgs {
  const DetailEditArgs({
    this.observation,
    this.scannedCode,
    this.sourceScreen,
    this.workGroupId,
    this.storeName,
    this.storeAddress,
    this.scanMatched,
    this.scanErrorMessage,
  });

  final PriceObservation? observation;
  final String? scannedCode;
  final String? sourceScreen;
  final String? workGroupId;
  final String? storeName;
  final String? storeAddress;
  final bool? scanMatched;
  final String? scanErrorMessage;
}
