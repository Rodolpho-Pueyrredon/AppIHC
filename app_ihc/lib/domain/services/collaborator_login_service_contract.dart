abstract interface class CollaboratorLoginServiceContract {
  Future<bool> login({required String username, required String password});
}
