import 'package:app_ihc/domain/models/session_work.dart';

abstract interface class CollaboratorWorksServiceContract {
  Future<List<SessionWork>> getWorksForCollaborator(String username);
}
