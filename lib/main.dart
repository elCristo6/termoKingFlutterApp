/*
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket Google Maps Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WebSocketMapDemo(),
    );
  }
}

class WebSocketMapDemo extends StatefulWidget {
  @override
  _WebSocketMapDemoState createState() => _WebSocketMapDemoState();
}

class _WebSocketMapDemoState extends State<WebSocketMapDemo> {
  // Actualiza la URL del WebSocket con la IP correcta si estás en un dispositivo físico
  final WebSocketChannel channel =
      IOWebSocketChannel.connect('ws://localhost:3000');

  GoogleMapController? _mapController;
  LatLng _currentPosition =
      LatLng(25.7617, -80.1918); // Posición inicial en Miami
  double _setTemperature = 3.0; // Setpoint de temperatura del dispositivo

  @override
  void initState() {
    super.initState();

    // Escuchar los datos entrantes del WebSocket
    channel.stream.listen((data) {
      print("Received raw data: $data"); // Imprimir el JSON recibido
      final parsedData = parseMessage(data);
      if (parsedData != null) {
        try {
          setState(() {
            _currentPosition = LatLng(
              _validateLatitude(parsedData['latitude']),
              _validateLongitude(parsedData['longitude'].isNegative
                  ? parsedData['longitude']
                  : -parsedData['longitude']),
            );
            _setTemperature = double.parse(parsedData['temperature']);
            _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
                _currentPosition, 19)); // Centrar y aplicar un zoom más cercano
          });
        } catch (e) {
          print("Error al validar las coordenadas: $e");
        }
      } else {
        print("Received data is null or not in the expected format.");
      }
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  double _validateLatitude(double latitude) {
    if (latitude < -90 || latitude > 90) {
      throw Exception('Latitude out of range: $latitude');
    }
    return latitude;
  }

  double _validateLongitude(double longitude) {
    if (longitude < -180 || longitude > 180) {
      throw Exception('Longitude out of range: $longitude');
    }
    return longitude;
  }

  void _showSetpointDialog() {
    TextEditingController _controller =
        TextEditingController(text: _setTemperature.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set Temperature'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        if (_setTemperature > -30) {
                          _setTemperature -= 0.5;
                          _controller.text = _setTemperature.toStringAsFixed(1);
                        }
                      });
                    },
                  ),
                  Container(
                    width: 60,
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        setState(() {
                          _setTemperature =
                              double.tryParse(value) ?? _setTemperature;
                          if (_setTemperature < -30) _setTemperature = -30;
                          if (_setTemperature > 30) _setTemperature = 30;
                          _controller.text = _setTemperature.toStringAsFixed(1);
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        if (_setTemperature < 30) {
                          _setTemperature += 0.5;
                          _controller.text = _setTemperature.toStringAsFixed(1);
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Set Temperature'),
              onPressed: () {
                _sendTemperatureCommand();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _sendTemperatureCommand() {
    // Enviar comando al servidor para cambiar el setpoint de temperatura del remolque
    channel.sink.add('{"setTemperature": $_setTemperature}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 19, // Zoom inicial más cercano
            ),
            markers: {
              Marker(
                markerId: MarkerId('currentLocation'),
                position: _currentPosition,
                infoWindow: InfoWindow(
                  title: 'Temperature',
                  snippet:
                      '$_setTemperature°C\nLat: ${_currentPosition.latitude}, Long: ${_currentPosition.longitude}', // Mostrar latitud y longitud junto con la temperatura en el InfoWindow
                ),
              ),
            },
          ),
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap:
                  _showSetpointDialog, // Abre el diálogo al tocar el recuadro
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.thermostat,
                        color: Colors.blue, size: 30), // Icono de temperatura
                    SizedBox(width: 5),
                    Text(
                      '$_setTemperature°C',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? parseMessage(String message) {
    try {
      final parsed = jsonDecode(message) as Map<String, dynamic>;
      print("Parsed JSON: $parsed"); // Imprimir el JSON parseado

      // Imprimir todas las claves del JSON para depuración
      print("Keys in JSON: ${parsed.keys}");

      // Verificar las claves con la capitalización correcta
      if (parsed.containsKey('GPS') &&
          parsed['GPS'] != null &&
          parsed.containsKey('Temperature')) {
        final gpsData = parsed['GPS'] as Map<String, dynamic>?;

        if (gpsData != null &&
            gpsData.containsKey('Latitude') &&
            gpsData.containsKey('Longitude')) {
          print(
              "GPS Data Found: Latitude=${gpsData['Latitude']}, Longitude=${gpsData['Longitude']}");
          return {
            'latitude': gpsData['Latitude'],
            'longitude': gpsData['Longitude'],
            'temperature': parsed['Temperature'].toString(),
          };
        } else {
          print("GPS data is missing or malformed.");
        }
      } else {
        print("Required keys are missing in the JSON.");
      }
    } catch (e) {
      print("Error parsing message: $e");
    }

    // Si los datos no son válidos o ocurre un error, retorna null
    return null;
  }
}
*/
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket Google Maps Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: UserIDScreen(),
    );
  }
}

class UserIDScreen extends StatefulWidget {
  @override
  _UserIDScreenState createState() => _UserIDScreenState();
}

class _UserIDScreenState extends State<UserIDScreen> {
  final TextEditingController _userIDController = TextEditingController();

  void _connect() {
    final String userID = _userIDController.text.trim();
    if (userID.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebSocketMapDemo(userID: userID),
        ),
      );
    } else {
      // Mostrar un mensaje de error si el userID está vacío
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa un User ID válido.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ingresar User ID'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userIDController,
              decoration: InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _connect,
              child: Text('Conectar'),
            ),
          ],
        ),
      ),
    );
  }
}

class WebSocketMapDemo extends StatefulWidget {
  final String userID;

  WebSocketMapDemo({required this.userID});

  @override
  _WebSocketMapDemoState createState() => _WebSocketMapDemoState();
}

class _WebSocketMapDemoState extends State<WebSocketMapDemo> {
  late WebSocketChannel channel;

  GoogleMapController? _mapController;
  LatLng _currentPosition =
      LatLng(25.7617, -80.1918); // Posición inicial en Miami
  double _setTemperature = 3.0; // Setpoint de temperatura del dispositivo

  @override
  void initState() {
    super.initState();

    // Establecer la conexión WebSocket con el userID como parámetro de consulta
    final String wsUrl = 'ws://localhost:3000?userID=${widget.userID}';
    channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));

    // Escuchar los datos entrantes del WebSocket
    channel.stream.listen((data) {
      print("Received raw data: $data"); // Imprimir el JSON recibido
      final parsedData = parseMessage(data);
      if (parsedData != null) {
        try {
          setState(() {
            _currentPosition = LatLng(
              _validateLatitude(parsedData['latitude']),
              _validateLongitude(parsedData['longitude']),
            );
            _setTemperature = parsedData['temperature'];
            _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
                _currentPosition, 19)); // Centrar y aplicar un zoom más cercano
          });
        } catch (e) {
          print("Error al validar las coordenadas: $e");
        }
      } else {
        print("Received data is null or not in the expected format.");
      }
    }, onError: (error) {
      print("WebSocket Error: $error");
      // Puedes manejar errores aquí, como mostrar una notificación al usuario
    }, onDone: () {
      print("WebSocket connection closed.");
      // Puedes intentar reconectar o notificar al usuario
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  double _validateLatitude(double latitude) {
    if (latitude < -90 || latitude > 90) {
      throw Exception('Latitude out of range: $latitude');
    }
    return latitude;
  }

  double _validateLongitude(double longitude) {
    if (longitude < -180 || longitude > 180) {
      throw Exception('Longitude out of range: $longitude');
    }
    return longitude;
  }

  double _adjustLongitude(double longitude) {
    // Asumiendo que todas las longitudes recibidas corresponden a ubicaciones en Colombia
    // y por lo tanto deben ser negativas
    return longitude > 0 ? -longitude : longitude;
  }

  Map<String, dynamic>? parseMessage(String message) {
    try {
      final parsed = jsonDecode(message) as Map<String, dynamic>;
      print("Parsed JSON: $parsed"); // Imprimir el JSON parseado

      // Imprimir todas las claves del JSON para depuración
      print("Keys in JSON: ${parsed.keys}");

      // Verificar las claves con la capitalización correcta
      if (parsed.containsKey('GPS') &&
          parsed['GPS'] != null &&
          parsed.containsKey('Temperature')) {
        final gpsData = parsed['GPS'] as Map<String, dynamic>?;

        if (gpsData != null &&
            gpsData.containsKey('Latitude') &&
            gpsData.containsKey('Longitude')) {
          double latitude;
          double longitude;

          // Asegurar que Latitude y Longitude sean de tipo double
          if (gpsData['Latitude'] is num && gpsData['Longitude'] is num) {
            latitude = (gpsData['Latitude'] as num).toDouble();
            longitude = (gpsData['Longitude'] as num).toDouble();
          } else {
            print("Latitude or Longitude is not a number.");
            return null;
          }

          // Ajustar la longitud para que sea negativa si corresponde
          longitude = _adjustLongitude(longitude);

          print("GPS Data Found: Latitude=$latitude, Longitude=$longitude");
          return {
            'latitude': latitude,
            'longitude': longitude,
            'temperature': (parsed['Temperature'] as num).toDouble(),
          };
        } else {
          print("GPS data is missing or malformed.");
        }
      } else {
        print("Required keys are missing in the JSON.");
      }
    } catch (e) {
      print("Error parsing message: $e");
    }

    // Si los datos no son válidos o ocurre un error, retorna null
    return null;
  }

  void _showSetpointDialog() {
    TextEditingController _controller =
        TextEditingController(text: _setTemperature.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set Temperature'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        if (_setTemperature > -30) {
                          _setTemperature -= 0.5;
                          _controller.text = _setTemperature.toStringAsFixed(1);
                        }
                      });
                    },
                  ),
                  Container(
                    width: 60,
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        setState(() {
                          _setTemperature =
                              double.tryParse(value) ?? _setTemperature;
                          if (_setTemperature < -30) _setTemperature = -30;
                          if (_setTemperature > 30) _setTemperature = 30;
                          _controller.text = _setTemperature.toStringAsFixed(1);
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        if (_setTemperature < 30) {
                          _setTemperature += 0.5;
                          _controller.text = _setTemperature.toStringAsFixed(1);
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Set Temperature'),
              onPressed: () {
                _sendTemperatureCommand();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _sendTemperatureCommand() {
    // Enviar comando al servidor para cambiar el setpoint de temperatura del remolque
    final command = jsonEncode({'setTemperature': _setTemperature});
    channel.sink.add(command);
    print("Sent command: $command");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 19, // Zoom inicial más cercano
            ),
            markers: {
              Marker(
                markerId: MarkerId('currentLocation'),
                position: _currentPosition,
                infoWindow: InfoWindow(
                  title: 'Temperature',
                  snippet:
                      '$_setTemperature°C\nLat: ${_currentPosition.latitude}, Long: ${_currentPosition.longitude}', // Mostrar latitud y longitud junto con la temperatura en el InfoWindow
                ),
              ),
            },
          ),
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap:
                  _showSetpointDialog, // Abre el diálogo al tocar el recuadro
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.thermostat,
                        color: Colors.blue, size: 30), // Icono de temperatura
                    SizedBox(width: 5),
                    Text(
                      '$_setTemperature°C',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
