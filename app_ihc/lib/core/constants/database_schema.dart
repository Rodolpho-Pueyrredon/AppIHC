abstract final class DatabaseSchema {
  static const databaseName = 'app_ihc.db';
  static const databaseVersion = 1;

  static const createProductsTable = '''
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    barcode TEXT NOT NULL UNIQUE,
    name TEXT,
    brand TEXT,
    category TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
''';

  static const createStoresTable = '''
CREATE TABLE stores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    normalized_name TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
''';

  static const createStoresNormalizedNameIndex = '''
CREATE INDEX idx_stores_normalized_name ON stores(normalized_name);
''';

  static const createPriceObservationsTable = '''
CREATE TABLE price_observations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL,
    store_id INTEGER NOT NULL,
    price_cents INTEGER NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    observed_at TEXT NOT NULL,
    notes TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (store_id) REFERENCES stores(id)
);
''';

  static const createPriceObsProductIdIndex = '''
CREATE INDEX idx_price_obs_product_id ON price_observations(product_id);
''';

  static const createPriceObsStoreIdIndex = '''
CREATE INDEX idx_price_obs_store_id ON price_observations(store_id);
''';

  static const createPriceObsObservedAtIndex = '''
CREATE INDEX idx_price_obs_observed_at ON price_observations(observed_at);
''';
}
