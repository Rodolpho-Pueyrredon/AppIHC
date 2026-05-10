import 'package:app_ihc/domain/models/session_work.dart';

abstract interface class SessionRepository {
  Future<void> saveSessionWorks(List<SessionWork> works);
  Future<void> clearSession();
}
