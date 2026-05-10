import 'package:app_ihc/core/config/supabase_api_config.dart';
import 'package:app_ihc/data/services/http_json_client.dart';
import 'package:app_ihc/domain/services/collaborator_login_service_contract.dart';

class SupabaseCollaboratorLoginService
    implements CollaboratorLoginServiceContract {
  SupabaseCollaboratorLoginService({
    required SupabaseApiConfig config,
    required HttpJsonClient httpJsonClient,
  }) : _config = config,
       _httpJsonClient = httpJsonClient;

  final SupabaseApiConfig _config;
  final HttpJsonClient _httpJsonClient;

  @override
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final response = await _httpJsonClient.postJson(
      _config.rpcUri('login_collaborator'),
      headers: _config.headers,
      body: {'p_username': username, 'p_password': password},
    );

    return response == true;
  }
}
