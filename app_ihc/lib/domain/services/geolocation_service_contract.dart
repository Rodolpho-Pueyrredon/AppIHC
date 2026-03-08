import 'package:app_ihc/domain/models/geo_point.dart';

abstract interface class GeolocationServiceContract {
  Future<GeoPoint?> getCurrentPosition();
}
