import 'package:app_ihc/core/config/product_lookup_api_config.dart';
import 'package:app_ihc/data/repositories/price_observation_repository_impl.dart';
import 'package:app_ihc/data/repositories/product_repository_impl.dart';
import 'package:app_ihc/data/repositories/store_repository_impl.dart';
import 'package:app_ihc/data/providers/barcode_lookup_lookup_provider.dart';
import 'package:app_ihc/data/providers/open_food_facts_lookup_provider.dart';
import 'package:app_ihc/data/providers/upc_item_db_lookup_provider.dart';
import 'package:app_ihc/data/services/http_json_client.dart';
import 'package:app_ihc/data/services/product_lookup_service.dart';
import 'package:app_ihc/data/services/sqlite_service.dart';
import 'package:app_ihc/data/services/stub_geolocation_service.dart';
import 'package:app_ihc/data/services/stub_scanner_service.dart';
import 'package:app_ihc/domain/repositories/price_observation_repository.dart';
import 'package:app_ihc/domain/repositories/product_repository.dart';
import 'package:app_ihc/domain/repositories/store_repository.dart';
import 'package:app_ihc/domain/services/geolocation_service_contract.dart';
import 'package:app_ihc/domain/services/product_lookup_service_contract.dart';
import 'package:app_ihc/domain/services/scanner_service_contract.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';
import 'package:app_ihc/domain/usecases/lookup_product_by_barcode_use_case.dart';

class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  late final ScannerServiceContract scannerService;
  late final GeolocationServiceContract geolocationService;
  late final SQLiteServiceContract sqliteService;
  late final ProductLookupServiceContract productLookupService;
  late final LookupProductByBarcodeUseCase lookupProductByBarcodeUseCase;
  late final ProductRepository productRepository;
  late final StoreRepository storeRepository;
  late final PriceObservationRepository priceObservationRepository;

  void setup() {
    scannerService = StubScannerService();
    geolocationService = StubGeolocationService();

    sqliteService = SQLiteService();

    final apiConfig = ProductLookupApiConfig.fromEnvironment();
    final httpJsonClient = DartHttpJsonClient();

    productRepository = ProductRepositoryImpl(sqliteService: sqliteService);
    storeRepository = StoreRepositoryImpl(sqliteService: sqliteService);
    productLookupService = ProductLookupService(
      productRepository: productRepository,
      providersInOrder: [
        OpenFoodFactsLookupProvider(httpJsonClient: httpJsonClient),
        UpcItemDbLookupProvider(
          httpJsonClient: httpJsonClient,
          apiKey: apiConfig.upcItemDbApiKey,
        ),
        BarcodeLookupLookupProvider(
          httpJsonClient: httpJsonClient,
          apiKey: apiConfig.barcodeLookupApiKey,
        ),
      ],
    );
    lookupProductByBarcodeUseCase = LookupProductByBarcodeUseCase(
      productLookupService: productLookupService,
    );
    priceObservationRepository = PriceObservationRepositoryImpl(
      sqliteService: sqliteService,
      productRepository: productRepository,
      storeRepository: storeRepository,
    );
  }
}
