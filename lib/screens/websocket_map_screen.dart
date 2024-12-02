import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';

class WebSocketMapScreen extends StatefulWidget {
  @override
  _WebSocketMapScreenState createState() => _WebSocketMapScreenState();
}

class _WebSocketMapScreenState extends State<WebSocketMapScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = LatLng(40.7128, -74.0060); // Coordenadas iniciales
  double _setTemperature = 21.0;
  int _runTime = 0;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D2671), Color(0xFFC33764)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 4),
                blurRadius: 8.0,
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Información del dispositivo y estado
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_userId',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _connectionStatus == 'Dispositivo desconectado'
                                ? Icons.error_outline
                                : Icons.check_circle,
                            color:
                                _connectionStatus == 'Dispositivo desconectado'
                                    ? Colors.redAccent
                                    : Colors.lightGreenAccent,
                            size: 16,
                          ),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              _connectionStatus,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Temperatura y Runtime
                Container(
                  child: Column(
                    children: [
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.thermostat_outlined,
                            color: Colors.blueAccent,
                            size: 30,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '${_setTemperature.toStringAsFixed(1)}°',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            color: Colors.orangeAccent,
                            size: 20,
                          ),
                          SizedBox(width: 5),
                          Text(
                            '$_runTime s',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // Botón de logout estilizado
                IconButton(
                  icon: Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 24,
                  ),
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
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Google Maps
          Expanded(
            child: Stack(
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
                  myLocationButtonEnabled: false,
                ),
              ],
            ),
          ),
          Container(
            color: Colors.grey[200],
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Acción del botón 1
                  },
                  icon: Icon(Icons.tornado_outlined, size: 18), // Smaller icon
                  label: Text(
                    "Tortuga",
                    style: TextStyle(fontSize: 12), // Smaller font size
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8), // Smaller padding
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: Size(60, 36), // Set a smaller minimum size
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Acción del botón 2
                  },
                  icon: Icon(Icons.mode_fan_off_sharp, size: 18),
                  label: Text(
                    "Frozzen",
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: Size(60, 36),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Acción del botón 3
                  },
                  icon: Icon(Icons.tv_sharp, size: 18),
                  label: Text(
                    "ON",
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: Size(60, 36),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Acción del botón 4
                  },
                  icon: Icon(Icons.tv_off, size: 18),
                  label: Text(
                    "OFF",
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: Size(60, 36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
