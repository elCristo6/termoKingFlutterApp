// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  String get userId {
    if (_token == null) return '';
    Map<String, dynamic> payload = Jwt.parseJwt(_token!);
    return payload['userId']?.toString() ?? '';
  }

  Future<void> loadToken() async {
    _token = await secureStorage.read(key: 'jwt_token');
    if (_token != null) {
      print('AuthProvider: Token cargado.');
      notifyListeners();
    } else {
      print('AuthProvider: No se encontró token.');
    }
  }

  Future<void> logout() async {
    await secureStorage.delete(key: 'jwt_token');
    _token = null;
    print('AuthProvider: Usuario desconectado.');
    notifyListeners();
  }
}
