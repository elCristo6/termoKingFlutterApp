// lib/services/auth_service.dart

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';

import '../providers/auth_provider.dart';

class AuthService {
  final String baseUrl = 'http://34.226.208.66:3002/api/';
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  Future<String?> loginUser(
      String userId, String password, AuthProvider authProvider) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'password': password}),
    );

    print('AuthService: Respuesta del servidor: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];

      if (token != null) {
        await secureStorage.write(key: 'jwt_token', value: token);
        print('AuthService: Usuario autenticado. Token recibido.');

        // Decodificar el token para obtener userId
        Map<String, dynamic> payload = Jwt.parseJwt(token);
        final userIdFromToken = payload['userId'];

        if (userIdFromToken != null) {
          // Establece userId en AuthProvider
          authProvider.setUserId(userIdFromToken);
        } else {
          print('AuthService: userId no encontrado en el token.');
        }

        return token;
      } else {
        print('AuthService: Token no encontrado en la respuesta.');
        return null;
      }
    } else {
      print('AuthService: Error al iniciar sesión: ${response.body}');
      return null;
    }
  }
}
