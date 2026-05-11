import 'package:app_ihc/domain/models/session_work_group.dart';

abstract interface class SessionWorkGroupsServiceContract {
  Future<List<SessionWorkGroup>> getWorkGroupsFromSession();
}
