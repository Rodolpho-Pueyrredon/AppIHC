import 'package:app_ihc/core/config/supabase_api_config.dart';
import 'package:app_ihc/data/repositories/collaborator_repository_impl.dart';
import 'package:app_ihc/data/repositories/price_observation_repository_impl.dart';
import 'package:app_ihc/data/repositories/product_repository_impl.dart';
import 'package:app_ihc/data/repositories/session_repository_impl.dart';
import 'package:app_ihc/data/repositories/store_repository_impl.dart';
import 'package:app_ihc/data/services/http_json_client.dart';
import 'package:app_ihc/data/services/product_lookup_service.dart';
import 'package:app_ihc/data/services/supabase_price_observation_sync_service.dart';
import 'package:app_ihc/data/services/supabase_session_products_sync_service.dart';
import 'package:app_ihc/data/services/supabase_session_work_groups_service.dart';
import 'package:app_ihc/data/services/sqlite_service.dart';
import 'package:app_ihc/data/services/supabase_collaborator_login_service.dart';
import 'package:app_ihc/data/services/supabase_collaborator_works_service.dart';
import 'package:app_ihc/data/services/stub_geolocation_service.dart';
import 'package:app_ihc/data/services/stub_scanner_service.dart';
import 'package:app_ihc/domain/repositories/collaborator_repository.dart';
import 'package:app_ihc/domain/repositories/price_observation_repository.dart';
import 'package:app_ihc/domain/repositories/product_repository.dart';
import 'package:app_ihc/domain/repositories/session_repository.dart';
import 'package:app_ihc/domain/repositories/store_repository.dart';
import 'package:app_ihc/domain/services/geolocation_service_contract.dart';
import 'package:app_ihc/domain/services/collaborator_login_service_contract.dart';
import 'package:app_ihc/domain/services/collaborator_works_service_contract.dart';
import 'package:app_ihc/domain/services/price_observation_sync_service_contract.dart';
import 'package:app_ihc/domain/services/product_lookup_service_contract.dart';
import 'package:app_ihc/domain/services/scanner_service_contract.dart';
import 'package:app_ihc/domain/services/session_products_sync_service_contract.dart';
import 'package:app_ihc/domain/services/session_work_groups_service_contract.dart';
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
  late final HttpJsonClient httpJsonClient;
  late final CollaboratorLoginServiceContract collaboratorLoginService;
  late final CollaboratorWorksServiceContract collaboratorWorksService;
  late final PriceObservationSyncServiceContract priceObservationSyncService;
  late final SessionProductsSyncServiceContract sessionProductsSyncService;
  late final SessionWorkGroupsServiceContract sessionWorkGroupsService;
  late final ProductLookupServiceContract productLookupService;
  late final LookupProductByBarcodeUseCase lookupProductByBarcodeUseCase;
  late final CollaboratorRepository collaboratorRepository;
  late final ProductRepository productRepository;
  late final SessionRepository sessionRepository;
  late final StoreRepository storeRepository;
  late final PriceObservationRepository priceObservationRepository;

  void setup() {
    authSession = AuthSession();
    scannerService = StubScannerService();
    geolocationService = StubGeolocationService();

    sqliteService = SQLiteService();
    httpJsonClient = DartHttpJsonClient();
    collaboratorLoginService = SupabaseCollaboratorLoginService(
      config: SupabaseApiConfig.fromEnvironment(),
      httpJsonClient: httpJsonClient,
    );
    collaboratorWorksService = SupabaseCollaboratorWorksService(
      config: SupabaseApiConfig.fromEnvironment(),
      httpJsonClient: httpJsonClient,
    );
    priceObservationSyncService = SupabasePriceObservationSyncService(
      config: SupabaseApiConfig.fromEnvironment(),
      httpJsonClient: httpJsonClient,
      sqliteService: sqliteService,
    );
    sessionProductsSyncService = SupabaseSessionProductsSyncService(
      config: SupabaseApiConfig.fromEnvironment(),
      httpJsonClient: httpJsonClient,
      sqliteService: sqliteService,
    );
    sessionWorkGroupsService = SupabaseSessionWorkGroupsService(
      config: SupabaseApiConfig.fromEnvironment(),
      httpJsonClient: httpJsonClient,
      sqliteService: sqliteService,
    );
    collaboratorRepository = CollaboratorRepositoryImpl(
      sqliteService: sqliteService,
    );
    productRepository = ProductRepositoryImpl(sqliteService: sqliteService);
    sessionRepository = SessionRepositoryImpl(sqliteService: sqliteService);
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
