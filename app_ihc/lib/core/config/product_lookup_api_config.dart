class ProductLookupApiConfig {
  const ProductLookupApiConfig({
    this.upcItemDbApiKey,
    this.barcodeLookupApiKey,
  });

  final String? upcItemDbApiKey;
  final String? barcodeLookupApiKey;

  factory ProductLookupApiConfig.fromEnvironment() {
    return const ProductLookupApiConfig(
      upcItemDbApiKey: String.fromEnvironment('UPCITEMDB_API_KEY'),
      barcodeLookupApiKey: String.fromEnvironment('BARCODELOOKUP_API_KEY'),
    );
  }
}
