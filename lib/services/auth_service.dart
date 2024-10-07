// lib/services/auth_service.dart

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl =
      'http://localhost:3000/api'; // Actualiza con tu URL de backend
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  Future<bool> registerUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Registro exitoso
      print('AuthService: Usuario registrado exitosamente.');
      return true;
    } else {
      // Manejo de errores
      print('AuthService: Error al registrar usuario: ${response.body}');
      return false;
    }
  }

  Future<String?> loginUser(String userId, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];

      if (token != null) {
        // Almacenar el token de manera segura
        await secureStorage.write(key: 'jwt_token', value: token);
        print('AuthService: Usuario autenticado. Token recibido.');
        return token;
      } else {
        print('AuthService: Token no encontrado en la respuesta.');
        return null;
      }
    } else {
      // Manejo de errores
      print('AuthService: Error al iniciar sesión: ${response.body}');
      return null;
    }
  }
}
