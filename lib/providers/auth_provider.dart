// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// lib/providers/auth_provider.dart

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userId; // Usamos solo userId aquí
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  String? get token => _token;
  String? get userId => _userId;
  bool get isAuthenticated => _token != null;

  Future<void> loadToken() async {
    _token = await secureStorage.read(key: 'jwt_token');
    if (_token != null) {
      print('AuthProvider: Token cargado.');
      notifyListeners();
    } else {
      print('AuthProvider: No se encontró token.');
    }
  }

  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }

  Future<void> logout() async {
    await secureStorage.delete(key: 'jwt_token');
    _token = null;
    _userId = null;
    print('AuthProvider: Usuario desconectado.');
    notifyListeners();
  }
}
