// lib/screens/websocket_map_screen.dart
/*

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import 'speedometer.dart';

class WebSocketMapScreen extends StatefulWidget {
  @override
  _WebSocketMapScreenState createState() => _WebSocketMapScreenState();
}

class _WebSocketMapScreenState extends State<WebSocketMapScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition =
      LatLng(40.7128, -74.0060); // Coordenadas iniciales de Nueva York
  double _setTemperature = 21.0; // Setpoint de temperatura del dispositivo
  int _runTime = 0;
  double _speed = 0.0;
  Set<Marker> _markers = {}; // Conjunto de marcadores
  String _connectionStatus = 'Esperando conexión...'; // Estado de conexión
  Timer? _disconnectTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      dataProvider.initialize(context);

      // Añadir listener para actualizar el marcador con los datos recibidos
      dataProvider.addListener(() {
        if (dataProvider.deviceData.isNotEmpty) {
          final deviceData = dataProvider.deviceData.last;
          if (deviceData.containsKey('GPS')) {
            _updateMarker(deviceData);
            _setConnectionStatus('Dispositivo conectado');
            _resetDisconnectTimer();
            _updateSpeed(deviceData);
          }
        }
      });
      _setConnectionStatus('Esperando dispositivo...');
    });
  }

  @override
  void dispose() {
    _disconnectTimer?.cancel();
    super.dispose();
  }

  void _setConnectionStatus(String status) {
    setState(() {
      _connectionStatus = status;
    });
  }

  void _resetDisconnectTimer() {
    _disconnectTimer?.cancel();
    _disconnectTimer = Timer(Duration(seconds: 5), () {
      _setConnectionStatus('Dispositivo desconectado');
    });
  }

  void _updateMarker(Map<String, dynamic> deviceData) {
    final gps = deviceData['GPS'];
    print('Actualizando marcador con data: $deviceData');

    try {
      double latitude = (gps['Latitude'] as num).toDouble();
      double longitude = (gps['Longitude'] as num).toDouble();

      // Asegura que la longitud esté en el formato correcto para Colombia
      if (longitude > 0) {
        longitude *= -1;
      }

      double temperature = (deviceData['Temperature'] as num).toDouble();
      int runTime = deviceData['RunTime'] ?? 0;

      print(
          'WebSocketMapScreen: Actualizando marcador en $_currentPosition con temperatura $_setTemperature°C');

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(latitude, longitude);
          _setTemperature = temperature;
          _runTime = runTime; // Actualiza el RunTime
          _markers = {
            Marker(
              markerId: MarkerId('currentLocation'),
              position: _currentPosition,
              infoWindow: InfoWindow(
                title: 'Temperatura',
                snippet:
                    '$_setTemperature°C\nLat: ${_currentPosition.latitude}, Long: ${_currentPosition.longitude}',
              ),
            ),
          };
        });
        _animateCamera();
      }
    } catch (e) {
      print('WebSocketMapScreen: Error al actualizar el marcador: $e');
    }
  }

  void _animateCamera() {
    print('WebSocketMapScreen: Animando cámara a $_currentPosition');
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 19),
    );
  }

  void _updateSpeed(Map<String, dynamic> deviceData) {
    final gps = deviceData['GPS'];
    double speedInMps = (gps['Speed'] as num).toDouble();
    int speedInKmh = (speedInMps * 3.6).round(); // Convertir a km/h y redondear

    setState(() {
      _speed = speedInMps < 1
          ? 0
          : speedInKmh.toDouble(); // Mostrar 0 km/h si está casi en reposo
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebSocket Google Maps Demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final dataProvider =
                  Provider.of<DataProvider>(context, listen: false);
              authProvider.logout();
              dataProvider.disconnect();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(30.0),
          child: Container(
            padding: EdgeInsets.all(8.0),
            child: Text(
              _connectionStatus,
              style: TextStyle(
                color: _connectionStatus == 'Dispositivo desconectado'
                    ? Colors.red
                    : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 19,
            ),
            markers: _markers, // Usar el conjunto de marcadores
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    TextEditingController _controller = TextEditingController(
                        text: _setTemperature.toStringAsFixed(1));

                    return AlertDialog(
                      title: Text('Modificar Setpoint de Temperatura'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _controller,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Nuevo Setpoint (°C)',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (value) {
                              double? newSetpoint = double.tryParse(value);
                              if (newSetpoint != null) {
                                setState(() {
                                  _setTemperature =
                                      newSetpoint.clamp(-30, 30).toDouble();
                                });
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          child: Text('Cancelar'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        ElevatedButton(
                          child: Text('Guardar'),
                          onPressed: () {
                            double? newSetpoint =
                                double.tryParse(_controller.text);
                            if (newSetpoint != null) {
                              setState(() {
                                _setTemperature =
                                    newSetpoint.clamp(-30, 30).toDouble();
                              });
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
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
                    Icon(Icons.thermostat, color: Colors.blue, size: 30),
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
          Positioned(
            top: 80,
            right: 20,
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
                  Icon(Icons.timer, color: Colors.orange, size: 30),
                  SizedBox(width: 5),
                  Text(
                    'RunTime: $_runTime s',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Speedometer(speed: _speed), // Usar speed como entero
          ),
        ],
      ),
    );
  }
}
*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import 'speedometer.dart';

class WebSocketMapScreen extends StatefulWidget {
  @override
  _WebSocketMapScreenState createState() => _WebSocketMapScreenState();
}

class _WebSocketMapScreenState extends State<WebSocketMapScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = LatLng(40.7128, -74.0060); // Coordenadas iniciales
  double _setTemperature = 21.0;
  int _runTime = 0;
  double _speed = 0.0;
  Set<Marker> _markers = {};
  String _connectionStatus = 'Esperando conexión...';
  Timer? _disconnectTimer;
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      setState(() {
        _userId = authProvider.userId ?? 'Esperando conexión';
      });

      dataProvider.initialize(context);
      dataProvider.addListener(() {
        if (dataProvider.deviceData.isNotEmpty) {
          final deviceData = dataProvider.deviceData.last;
          if (deviceData.containsKey('GPS')) {
            _updateMarker(deviceData);
            _setConnectionStatus('Dispositivo conectado');
            _resetDisconnectTimer();
            _updateSpeed(deviceData);
          }
        }
      });
      _setConnectionStatus('Esperando dispositivo...');
    });
  }

  @override
  void dispose() {
    _disconnectTimer?.cancel();
    super.dispose();
  }

  void _setConnectionStatus(String status) {
    if (mounted) {
      setState(() {
        _connectionStatus = status;
      });
    }
  }

  void _resetDisconnectTimer() {
    _disconnectTimer?.cancel();
    _disconnectTimer = Timer(Duration(seconds: 5), () {
      _setConnectionStatus('Dispositivo desconectado');
    });
  }

  void _updateMarker(Map<String, dynamic> deviceData) {
    final gps = deviceData['GPS'];
    if (gps == null) {
      _setConnectionStatus('Sin señal GPS');
      return;
    }

    try {
      double latitude =
          (gps['Latitude'] as num?)?.toDouble() ?? _currentPosition.latitude;
      double longitude =
          (gps['Longitude'] as num?)?.toDouble() ?? _currentPosition.longitude;

      if (longitude > 0) longitude *= -1;
      double temperature = (deviceData['Temperature'] as num).toDouble();
      int runTime = deviceData['RunTime'] ?? 0;

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(latitude, longitude);
          _setTemperature = temperature;
          _runTime = runTime;
          _markers = {
            Marker(
              markerId: MarkerId('currentLocation'),
              position: _currentPosition,
              infoWindow: InfoWindow(
                title: 'Temperatura',
                snippet:
                    '$_setTemperature°C\nLat: ${_currentPosition.latitude}, Long: ${_currentPosition.longitude}',
              ),
            ),
          };
        });
        _animateCamera();
      }
    } catch (e) {
      print('WebSocketMapScreen: Error al actualizar el marcador: $e');
    }
  }

  void _animateCamera() {
    if (mounted) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 19),
      );
    }
  }

  void _updateSpeed(Map<String, dynamic> deviceData) {
    final gps = deviceData['GPS'];
    double speedInMps = (gps['Speed'] as num?)?.toDouble() ?? 0.0;
    int speedInKmh = (speedInMps * 3.6).round();

    if (mounted) {
      setState(() {
        _speed = speedInMps < 1 ? 0 : speedInKmh.toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dispositivo: $_userId'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final dataProvider =
                  Provider.of<DataProvider>(context, listen: false);
              authProvider.logout();
              dataProvider.disconnect();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(30.0),
          child: Container(
            padding: EdgeInsets.all(8.0),
            child: Text(
              _connectionStatus,
              style: TextStyle(
                color: _connectionStatus == 'Dispositivo desconectado'
                    ? Colors.red
                    : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 19,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    TextEditingController _controller = TextEditingController(
                        text: _setTemperature.toStringAsFixed(1));

                    return AlertDialog(
                      title: Text('Modificar Setpoint de Temperatura'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _controller,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Nuevo Setpoint (°C)',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (value) {
                              double? newSetpoint = double.tryParse(value);
                              if (newSetpoint != null) {
                                setState(() {
                                  _setTemperature =
                                      newSetpoint.clamp(-30, 30).toDouble();
                                });
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          child: Text('Cancelar'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        ElevatedButton(
                          child: Text('Guardar'),
                          onPressed: () {
                            double? newSetpoint =
                                double.tryParse(_controller.text);
                            if (newSetpoint != null) {
                              setState(() {
                                _setTemperature =
                                    newSetpoint.clamp(-30, 30).toDouble();
                              });
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
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
                    Icon(Icons.thermostat, color: Colors.blue, size: 30),
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
          Positioned(
            top: 80,
            right: 20,
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
                  Icon(Icons.timer, color: Colors.orange, size: 30),
                  SizedBox(width: 5),
                  Text(
                    'RunTime: $_runTime s',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Speedometer(speed: _speed),
          ),
        ],
      ),
    );
  }
}
