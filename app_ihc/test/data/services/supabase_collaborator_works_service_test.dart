import 'package:app_ihc/core/config/supabase_api_config.dart';
import 'package:app_ihc/data/services/http_json_client.dart';
import 'package:app_ihc/data/services/supabase_collaborator_works_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHttpJsonClient implements HttpJsonClient {
  Uri? lastUri;

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async {
    lastUri = uri;
    return [
      {'collaborator_username': 'miao_yin@empresa.com', 'work_id': 'work-1'},
    ];
  }

  @override
  Future<dynamic> postJson(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  test('loads only unfinished works for collaborator', () async {
    final httpClient = _FakeHttpJsonClient();
    final service = SupabaseCollaboratorWorksService(
      config: const SupabaseApiConfig(baseUrl: 'https://example.com/rest/v1'),
      httpJsonClient: httpClient,
    );

    final works = await service.getWorksForCollaborator('miao_yin@empresa.com');

    expect(works, hasLength(1));
    expect(works.single.workId, 'work-1');
    expect(
      httpClient.lastUri.toString(),
      'https://example.com/rest/v1/works_full?collaborator_username=eq.miao_yin%40empresa.com&done=eq.false',
    );
  });
}
