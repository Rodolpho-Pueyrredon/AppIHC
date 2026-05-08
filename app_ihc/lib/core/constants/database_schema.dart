abstract final class DatabaseSchema {
  static const databaseName = 'app_ihc.db';
  static const databaseVersion = 1;

  static const createProductsTable = '''
CREATE TABLE products (
    barcode TEXT PRIMARY KEY,
    category TEXT,
    brand TEXT,
    name TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
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

  static const createPriceObservationsTable = '''
CREATE TABLE price_observations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_barcode TEXT NOT NULL,
    store_id INTEGER NOT NULL,
    price_cents INTEGER NOT NULL,
    observed_at TEXT NOT NULL,
    notes TEXT,
    created_at TEXT NOT NULL,
    collaborator_id INTEGER REFERENCES collaborator(id),
    FOREIGN KEY (product_barcode) REFERENCES products(barcode),
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

  static const createPriceObsCollaboratorIdIndex = '''
CREATE INDEX idx_price_obs_collaborator_id ON price_observations(collaborator_id);
''';
}
