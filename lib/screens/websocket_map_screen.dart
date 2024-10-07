// lib/screens/websocket_map_screen.dart

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
  LatLng _currentPosition =
      LatLng(4.494974, -74.115257); // Coordenadas iniciales corregidas
  double _setTemperature = 21.0; // Setpoint de temperatura del dispositivo
  Marker? _currentMarker;

  @override
  void initState() {
    super.initState();
    // Inicializar DataProvider y añadir listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      dataProvider.initialize(context);

      dataProvider.addListener(() {
        if (dataProvider.deviceData.isNotEmpty) {
          final deviceData = dataProvider.deviceData.last;
          _updateMarker(deviceData);
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    // No es necesario cerrar la conexión WebSocket aquí, DataProvider lo maneja
  }

  void _updateMarker(Map<String, dynamic> deviceData) {
    final gps = deviceData['GPS'];

    try {
      double latitude = (gps['Latitude'] as num).toDouble();
      double longitude = ((gps['Longitude'] as num).toDouble()) *
          -1; // Corregir longitud para Colombia
      double temperature = (deviceData['Temperature'] as num).toDouble();

      _currentPosition = LatLng(latitude, longitude);
      _setTemperature = temperature;

      print(
          'WebSocketMapScreen: Actualizando marcador en $_currentPosition con temperatura $_setTemperature°C');

      // Programar setState para después de la construcción actual
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentMarker = Marker(
              markerId: MarkerId('currentLocation'),
              position: _currentPosition,
              infoWindow: InfoWindow(
                title: 'Temperature',
                snippet:
                    '$_setTemperature°C\nLat: ${_currentPosition.latitude}, Long: ${_currentPosition.longitude}',
              ),
            );
          });

          _animateCamera();
        }
      });
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

  void _showSetpointDialog(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
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
                      if (_setTemperature > -30) {
                        setState(() {
                          _setTemperature -= 0.5;
                          _controller.text = _setTemperature.toStringAsFixed(1);
                        });
                      }
                    },
                  ),
                  Container(
                    width: 60,
                    child: TextField(
                      controller: _controller,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        double? temp = double.tryParse(value);
                        if (temp != null) {
                          setState(() {
                            _setTemperature = temp.clamp(-30, 30).toDouble();
                            _controller.text =
                                _setTemperature.toStringAsFixed(1);
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      if (_setTemperature < 30) {
                        setState(() {
                          _setTemperature += 0.5;
                          _controller.text = _setTemperature.toStringAsFixed(1);
                        });
                      }
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
                print(
                    'WebSocketMapScreen: SetPoint a enviar: $_setTemperature°C');
                dataProvider.setSetPoint(_setTemperature);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await authProvider.logout();
    dataProvider.disconnect(); // Cerrar WebSocket
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebSocket Google Maps Demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              // _updateMarker es llamado vía listener
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 19,
            ),
            markers: _currentMarker != null ? {_currentMarker!} : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () => _showSetpointDialog(context),
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
        ],
      ),
    );
  }
}
