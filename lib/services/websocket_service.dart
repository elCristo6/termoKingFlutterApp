// lib/services/websocket_service.dart

import 'dart:async'; // Añadir esta importación
import 'dart:convert';

import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

typedef OnDataReceived = void Function(Map<String, dynamic> data);

class WebSocketService {
  WebSocketChannel? _channel;
  final OnDataReceived onDataReceived;
  bool _isConnected = false;
  StreamSubscription? _subscription; // Añadir esta línea

  WebSocketService({required this.onDataReceived});

  void connect(String token) {
    if (_isConnected) {
      print('WebSocketService: Ya está conectado.');
      return;
    }
    print('WebSocketService: Intentando conectar con token.');
    // Reemplaza 'localhost' con la dirección de tu servidor si es necesario
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:3000/?token=$token'),
    );

    _subscription = _channel!.stream.listen(
      (message) {
        print('WebSocketService: Mensaje recibido: $message');
        try {
          final data = jsonDecode(message);
          onDataReceived(data);
        } catch (e) {
          print('WebSocketService: Error al decodificar mensaje JSON: $e');
        }
      },
      onError: (error) {
        print('WebSocketService: Error en WebSocket: $error');
        _isConnected = false;
      },
      onDone: () {
        print('WebSocketService: Conexión WebSocket cerrada.');
        _isConnected = false;
        _subscription?.cancel(); // Cancelar la suscripción
      },
    );

    _isConnected = true;
  }

  void sendTemperatureCommand(double setPoint) {
    if (_channel != null && _isConnected) {
      final command = {
        'command': 'setPoint',
        'value': setPoint,
      };
      _channel!.sink.add(jsonEncode(command));
      print('WebSocketService: Comando de setPoint enviado: $setPoint°C');
    } else {
      print(
          'WebSocketService: No se puede enviar setPoint, WebSocket no está conectado.');
    }
  }

  void disconnect() {
    if (_channel != null) {
      print('WebSocketService: Cerrando conexión WebSocket.');
      _channel!.sink.close(status.goingAway);
      _isConnected = false;
      _subscription?.cancel(); // Cancelar la suscripción
    }
  }

  bool get isConnected => _isConnected;
}
