import 'package:app_ihc/data/repositories/price_observation_repository_impl.dart';
import 'package:app_ihc/data/repositories/product_repository_impl.dart';
import 'package:app_ihc/data/repositories/store_repository_impl.dart';
import 'package:app_ihc/data/services/sqlite_service.dart';
import 'package:app_ihc/data/services/stub_geolocation_service.dart';
import 'package:app_ihc/data/services/stub_scanner_service.dart';
import 'package:app_ihc/domain/repositories/price_observation_repository.dart';
import 'package:app_ihc/domain/repositories/product_repository.dart';
import 'package:app_ihc/domain/repositories/store_repository.dart';
import 'package:app_ihc/domain/services/geolocation_service_contract.dart';
import 'package:app_ihc/domain/services/scanner_service_contract.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';

class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  late final ScannerServiceContract scannerService;
  late final GeolocationServiceContract geolocationService;
  late final SQLiteServiceContract sqliteService;
  late final ProductRepository productRepository;
  late final StoreRepository storeRepository;
  late final PriceObservationRepository priceObservationRepository;

  void setup() {
    scannerService = StubScannerService();
    geolocationService = StubGeolocationService();

    sqliteService = SQLiteService();
    sqliteService.init();

    productRepository = ProductRepositoryImpl(sqliteService: sqliteService);
    storeRepository = StoreRepositoryImpl(sqliteService: sqliteService);
    priceObservationRepository = PriceObservationRepositoryImpl(
      sqliteService: sqliteService,
      productRepository: productRepository,
      storeRepository: storeRepository,
    );
  }
}
