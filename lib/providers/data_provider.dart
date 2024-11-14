// lib/providers/data_provider.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/websocket_service.dart';
import 'auth_provider.dart';

class DataProvider with ChangeNotifier {
  WebSocketService? _webSocketService;
  final List<Map<String, dynamic>> _deviceData = [];
  bool _isDisposed = false;
  bool _isDeviceActive = false;
  AuthProvider? authProvider;

  bool get isDeviceActive => _isDeviceActive;
  List<Map<String, dynamic>> get deviceData => _deviceData;

  void initialize(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider!.isAuthenticated && authProvider!.token != null) {
      print('DataProvider: Inicializando WebSocketService con token y userId.');
      _webSocketService = WebSocketService(
        onDataReceived: (data) =>
            _handleDataReceived(data, authProvider!.userId!), // Usa userId aquí
        deviceID: authProvider!.userId!, // Usa userId en lugar de deviceID
      );
      _webSocketService!.connect(authProvider!.token!);
    } else {
      print('DataProvider: Usuario no autenticado o userId no disponible.');
    }
  }

  void _handleDataReceived(Map<String, dynamic> data, String userId) {
    if (_isDisposed) return;

    print('DataProvider: Datos recibidos: $data');
    final receivedUserId = data['userId'];
    print(
        'DataProvider: Comparando userId: esperado=$userId, recibido=$receivedUserId');

    if (receivedUserId == userId) {
      print('DataProvider: Datos pertenecen al usuario autenticado.');
      _deviceData.add(data);
      notifyListeners();
    } else {
      print('DataProvider: Mensaje recibido para otro usuario.');
    }
  }

  void setSetPoint(double setPoint) {
    print('DataProvider: Enviando setPoint: $setPoint°C');
    if (_webSocketService != null && _webSocketService!.isConnected) {
      _webSocketService!.sendTemperatureCommand(setPoint);
    } else {
      print('DataProvider: WebSocketService no está conectado.');
    }
  }

  void requestDeviceStatus() {
    print('DataProvider: Solicitando estado del dispositivo.');
    _webSocketService?.requestDeviceStatus();
  }

  void disconnect() {
    print('DataProvider: Desconectando WebSocket.');
    _webSocketService?.disconnect();
  }

  @override
  void dispose() {
    _isDisposed = true;
    print('DataProvider: Destruyendo y cerrando WebSocket.');
    _webSocketService?.disconnect();
    super.dispose();
  }
}
