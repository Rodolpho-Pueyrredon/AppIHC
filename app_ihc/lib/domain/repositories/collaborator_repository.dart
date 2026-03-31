import 'package:app_ihc/domain/models/collaborator.dart';

abstract interface class CollaboratorRepository {
  Future<Collaborator?> findByUsername(String username);
  Future<Collaborator?> findById(int id);
  Future<Collaborator> findOrCreateByUsername(String username);
}
