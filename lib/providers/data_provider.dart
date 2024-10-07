// lib/providers/data_provider.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/websocket_service.dart';
import 'auth_provider.dart';

class DataProvider with ChangeNotifier {
  WebSocketService? _webSocketService;
  List<Map<String, dynamic>> _deviceData = [];
  bool _isDisposed = false; // Añadir esta línea

  List<Map<String, dynamic>> get deviceData => _deviceData;

  void initialize(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated && authProvider.token != null) {
      print('DataProvider: Inicializando WebSocketService con token.');
      _webSocketService = WebSocketService(
        onDataReceived: (data) =>
            _handleDataReceived(data, authProvider.userId),
      );
      _webSocketService!.connect(authProvider.token!);
    } else {
      print('DataProvider: Usuario no autenticado o token nulo.');
    }
  }

  void _handleDataReceived(Map<String, dynamic> data, String userId) {
    if (_isDisposed) return; // Añadir esta línea

    print('DataProvider: Datos recibidos: $data');
    // Verificar si el userId en los datos coincide con el userId autenticado
    if (data['userId'] == userId) {
      print('DataProvider: Datos pertenecen al usuario autenticado.');
      _deviceData.add(data);
      notifyListeners();
    } else {
      print(
          'DataProvider: Datos recibidos para otro usuario: ${data['userId']}');
    }
  }

  void setSetPoint(double setPoint) {
    print('DataProvider: Enviando setPoint: $setPoint°C');
    // Enviar el setPoint al backend a través del WebSocket
    if (_webSocketService != null && _webSocketService!.isConnected) {
      _webSocketService!.sendTemperatureCommand(setPoint);
    } else {
      print(
          'DataProvider: WebSocketService no está inicializado o no está conectado.');
    }
  }

  void disconnect() {
    print('DataProvider: Desconectando WebSocket.');
    _webSocketService?.disconnect();
  }

  @override
  void dispose() {
    _isDisposed = true; // Añadir esta línea
    print('DataProvider: Destruyendo y cerrando WebSocket.');
    _webSocketService?.disconnect();
    super.dispose();
  }
}
