class SupabaseApiConfig {
  const SupabaseApiConfig({required this.baseUrl, this.anonKey});

  final String baseUrl;
  final String? anonKey;

  Uri rpcUri(String functionName) {
    return Uri.parse('$baseUrl/rpc/$functionName');
  }

  Uri tableUri(String tableName, {Map<String, String>? queryParameters}) {
    return Uri.parse(
      '$baseUrl/$tableName',
    ).replace(queryParameters: queryParameters);
  }

  Map<String, String> get headers {
    final key = anonKey?.trim();
    return {
      'Accept': 'application/json',
      if (key != null && key.isNotEmpty) ...{
        'apikey': key,
        'Authorization': 'Bearer $key',
      },
    };
  }

  factory SupabaseApiConfig.fromEnvironment() {
    return const SupabaseApiConfig(
      baseUrl: 'https://gohjpcxekvkgahiqncjw.supabase.co/rest/v1',
      anonKey: String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'sb_publishable_sCNqy-V9zhoqlVlTL3EreA_22UEmJXy',
      ),
    );
  }
}
