import 'package:app_ihc/domain/models/geo_point.dart';
import 'package:app_ihc/domain/services/geolocation_service_contract.dart';

class StubGeolocationService implements GeolocationServiceContract {
  @override
  Future<GeoPoint?> getCurrentPosition() async {
    // Coordenada fixa para desenvolvimento inicial.
    return const GeoPoint(latitude: -23.55052, longitude: -46.63331);
  }
}
