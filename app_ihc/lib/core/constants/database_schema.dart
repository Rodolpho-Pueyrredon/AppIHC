abstract final class DatabaseSchema {
  static const databaseName = 'app_ihc.db';
  static const databaseVersion = 1;

  static const createProductsTable = '''
CREATE TABLE products (
    barcode TEXT NOT NULL,
    work_id TEXT NOT NULL,
    category TEXT,
    brand TEXT,
    product_name TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    PRIMARY KEY (barcode, work_id)
);
''';

  static const createStoresTable = '''
CREATE TABLE stores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    address TEXT,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
''';

  static const createCollaboratorTable = '''
CREATE TABLE collaborator (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE CHECK (length(username) <= 250),
    friendly_name TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
''';

  static const createCollaboratorUsernameIndex = '''
CREATE INDEX idx_collaborator_username ON collaborator(username);
''';

  static const createSessionTable = '''
CREATE TABLE IF NOT EXISTS sessao (
    user TEXT NOT NULL,
    work_id TEXT NOT NULL
);
''';

  static const createPriceObservationsTable = '''
CREATE TABLE price_observations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_barcode TEXT NOT NULL,
    store_id INTEGER NOT NULL,
    price_cents INTEGER NOT NULL,
    observed_at TEXT NOT NULL,
    notes TEXT,
    created_at TEXT NOT NULL,
    work_id TEXT NOT NULL,
    FOREIGN KEY (product_barcode, work_id) REFERENCES products(barcode, work_id),
    FOREIGN KEY (store_id) REFERENCES stores(id)
);
''';

  static const createPriceObsProductBarcodeIndex = '''
CREATE INDEX idx_price_obs_product_barcode ON price_observations(product_barcode);
''';

  static const createPriceObsStoreIdIndex = '''
CREATE INDEX idx_price_obs_store_id ON price_observations(store_id);
''';

  static const createPriceObsObservedAtIndex = '''
CREATE INDEX idx_price_obs_observed_at ON price_observations(observed_at);
''';

  static const createPriceObsWorkIdIndex = '''
CREATE INDEX idx_price_obs_work_id ON price_observations(work_id);
''';
}
