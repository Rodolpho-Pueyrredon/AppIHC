import 'package:app_ihc/domain/models/price_observation.dart';

abstract interface class PriceObservationRepository {
  Future<List<PriceObservation>> getObservations();
  Future<List<PriceObservation>> getObservationsByWorkId(String workId);
  Future<PriceObservation?> getById(int id);
  Future<PriceObservation> saveObservation(PriceObservation observation);
  Future<void> updateObservation(PriceObservation observation);
  Future<void> deleteObservation(int id);
}
