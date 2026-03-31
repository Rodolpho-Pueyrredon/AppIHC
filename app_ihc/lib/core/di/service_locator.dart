import 'package:app_ihc/data/repositories/collaborator_repository_impl.dart';
import 'package:app_ihc/data/repositories/price_observation_repository_impl.dart';
import 'package:app_ihc/data/repositories/product_repository_impl.dart';
import 'package:app_ihc/data/repositories/store_repository_impl.dart';
import 'package:app_ihc/data/services/product_lookup_service.dart';
import 'package:app_ihc/data/services/sqlite_service.dart';
import 'package:app_ihc/data/services/stub_geolocation_service.dart';
import 'package:app_ihc/data/services/stub_scanner_service.dart';
import 'package:app_ihc/domain/repositories/collaborator_repository.dart';
import 'package:app_ihc/domain/repositories/price_observation_repository.dart';
import 'package:app_ihc/domain/repositories/product_repository.dart';
import 'package:app_ihc/domain/repositories/store_repository.dart';
import 'package:app_ihc/domain/services/geolocation_service_contract.dart';
import 'package:app_ihc/domain/services/product_lookup_service_contract.dart';
import 'package:app_ihc/domain/services/scanner_service_contract.dart';
import 'package:app_ihc/domain/services/sqlite_service_contract.dart';
import 'package:app_ihc/domain/usecases/lookup_product_by_barcode_use_case.dart';
import 'package:app_ihc/presentation/state/auth_session.dart';

class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  late final AuthSession authSession;
  late final ScannerServiceContract scannerService;
  late final GeolocationServiceContract geolocationService;
  late final SQLiteServiceContract sqliteService;
  late final ProductLookupServiceContract productLookupService;
  late final LookupProductByBarcodeUseCase lookupProductByBarcodeUseCase;
  late final CollaboratorRepository collaboratorRepository;
  late final ProductRepository productRepository;
  late final StoreRepository storeRepository;
  late final PriceObservationRepository priceObservationRepository;

  void setup() {
    authSession = AuthSession();
    scannerService = StubScannerService();
    geolocationService = StubGeolocationService();

    sqliteService = SQLiteService();
    collaboratorRepository = CollaboratorRepositoryImpl(
      sqliteService: sqliteService,
    );
    productRepository = ProductRepositoryImpl(sqliteService: sqliteService);
    storeRepository = StoreRepositoryImpl(sqliteService: sqliteService);
    productLookupService = ProductLookupService(
      productRepository: productRepository,
    );
    lookupProductByBarcodeUseCase = LookupProductByBarcodeUseCase(
      productLookupService: productLookupService,
    );
    priceObservationRepository = PriceObservationRepositoryImpl(
      sqliteService: sqliteService,
      productRepository: productRepository,
      storeRepository: storeRepository,
      authSession: authSession,
    );
  }
}
