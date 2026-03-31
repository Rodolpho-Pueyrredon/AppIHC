import 'package:flutter/foundation.dart';

class AuthSession extends ChangeNotifier {
  String? _username;
  int? _collaboratorId;

  String? get username => _username;
  int? get collaboratorId => _collaboratorId;
  bool get isLoggedIn => (_username ?? '').trim().isNotEmpty;

  void login({
    required String username,
    required int collaboratorId,
  }) {
    _username = username.trim();
    _collaboratorId = collaboratorId;
    notifyListeners();
  }

  void logout() {
    _username = null;
    _collaboratorId = null;
    notifyListeners();
  }
}
