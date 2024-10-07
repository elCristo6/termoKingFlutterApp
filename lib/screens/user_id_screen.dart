// lib/screens/user_id_screen.dart
/*
import 'package:flutter/material.dart';

import '../services/ websocket_map_screen.dart';

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
          builder: (context) => WebSocketMapScreen(userID: userID),
        ),
      );
    } else {
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
        ));
  }
}
*/