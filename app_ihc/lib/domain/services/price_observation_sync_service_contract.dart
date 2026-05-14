import 'package:app_ihc/domain/models/price_observation_sync_key.dart';

abstract interface class PriceObservationSyncServiceContract {
  Future<List<PriceObservationSyncKey>> insertPriceObservationRows(
    List<Map<String, Object?>> rows,
  );

  Future<List<PriceObservationSyncKey>> syncLocalPriceObservations();

  Future<List<PriceObservationSyncKey>> syncLocalPriceObservationsForWorkIds(
    Iterable<String> workIds,
  );
}
