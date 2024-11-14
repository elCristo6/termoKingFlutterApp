// lib/services/websocket_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

typedef OnDataReceived = void Function(Map<String, dynamic> data);

class WebSocketService {
  WebSocketChannel? _channel;
  final OnDataReceived onDataReceived;
  final String deviceID;
  bool _isConnected = false;
  StreamSubscription? _subscription;

  WebSocketService({required this.onDataReceived, required this.deviceID});

  void connect(String token) {
    if (_isConnected) {
      print('WebSocketService: Ya está conectado.');
      return;
    }

    print('WebSocketService: Conectando con token y deviceID.');
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://34.226.208.66:3002/?token=$token&deviceID=$deviceID'),
    );

    _subscription = _channel!.stream.listen(
      (message) {
        print('WebSocketService: Mensaje recibido: $message');
        try {
          final data = jsonDecode(message);
          if (data['deviceID'] == deviceID) {
            onDataReceived(data);
          } else {
            print('WebSocketService: Mensaje recibido para otro dispositivo.');
          }
        } catch (e) {
          print('WebSocketService: Error al decodificar JSON: $e');
        }
      },
      onError: (error) {
        print('WebSocketService: Error en WebSocket: $error');
        _isConnected = false;
      },
      onDone: () {
        print('WebSocketService: Conexión cerrada.');
        _isConnected = false;
        _subscription?.cancel();
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

  void requestDeviceStatus() {
    if (_channel != null && _isConnected) {
      final request = {
        'command': 'requestStatus',
      };
      _channel!.sink.add(jsonEncode(request));
      print('WebSocketService: Solicitud de estado del dispositivo enviada.');
    } else {
      print(
          'WebSocketService: No se puede solicitar estado, WebSocket no está conectado.');
    }
  }

  void disconnect() {
    if (_channel != null) {
      print('WebSocketService: Cerrando conexión WebSocket.');
      _channel!.sink.close();
      _isConnected = false;
      _subscription?.cancel();
    }
  }

  bool get isConnected => _isConnected;
}
