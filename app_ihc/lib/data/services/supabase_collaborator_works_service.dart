import 'package:app_ihc/core/config/supabase_api_config.dart';
import 'package:app_ihc/data/services/http_json_client.dart';
import 'package:app_ihc/domain/models/session_work.dart';
import 'package:app_ihc/domain/services/collaborator_works_service_contract.dart';

class SupabaseCollaboratorWorksService
    implements CollaboratorWorksServiceContract {
  SupabaseCollaboratorWorksService({
    required SupabaseApiConfig config,
    required HttpJsonClient httpJsonClient,
  }) : _config = config,
       _httpJsonClient = httpJsonClient;

  final SupabaseApiConfig _config;
  final HttpJsonClient _httpJsonClient;

  @override
  Future<List<SessionWork>> getWorksForCollaborator(String username) async {
    final response = await _httpJsonClient.getJson(
      _config.tableUri(
        'works_full',
        queryParameters: {'collaborator_username': 'eq.${username.trim()}'},
      ),
      headers: _config.headers,
    );

    if (response is! List) {
      return const [];
    }

    final worksByKey = <String, SessionWork>{};
    for (final item in response) {
      if (item is! Map<String, Object?>) {
        continue;
      }

      final collaboratorUsername = (item['collaborator_username'] as String?)
          ?.trim();
      final workId = (item['work_id'] as String?)?.trim();
      if (collaboratorUsername == null ||
          collaboratorUsername.isEmpty ||
          workId == null ||
          workId.isEmpty) {
        continue;
      }

      worksByKey['$collaboratorUsername|$workId'] = SessionWork(
        username: collaboratorUsername,
        workId: workId,
      );
    }

    return worksByKey.values.toList(growable: false);
  }
}
