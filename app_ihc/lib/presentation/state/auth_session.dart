import 'package:flutter/foundation.dart';

class AuthSession extends ChangeNotifier {
  String? _username;
  int? _collaboratorId;
  String? _workGroupId;
  String? _storeName;
  String? _storeAddress;

  String? get username => _username;
  int? get collaboratorId => _collaboratorId;
  String? get workGroupId => _workGroupId;
  String? get storeName => _storeName;
  String? get storeAddress => _storeAddress;
  bool get isLoggedIn => (_username ?? '').trim().isNotEmpty;

  void login({required String username, int? collaboratorId}) {
    _username = username.trim();
    _collaboratorId = collaboratorId;
    notifyListeners();
  }

  void selectWorkGroup({
    required String workGroupId,
    String? storeName,
    String? storeAddress,
  }) {
    _workGroupId = workGroupId.trim();
    _storeName = storeName?.trim();
    _storeAddress = storeAddress?.trim();
    notifyListeners();
  }

  void logout() {
    _username = null;
    _collaboratorId = null;
    _workGroupId = null;
    _storeName = null;
    _storeAddress = null;
    notifyListeners();
  }
}
