// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'screens/login_screen.dart';
import 'screens/websocket_map_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<DataProvider>(create: (_) => DataProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AuthProvider authProvider;

  @override
  void initState() {
    super.initState();
    // Cargar el token cuando la aplicación se inicia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.loadToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          title: 'Termoking App',
          debugShowCheckedModeBanner: false,
          routes: {
            '/login': (_) => LoginScreen(),
            '/map': (_) => WebSocketMapScreen(),
          },
          home: auth.isAuthenticated ? WebSocketMapScreen() : LoginScreen(),
          onGenerateRoute: (settings) {
            if (settings.name == '/map') {
              return MaterialPageRoute(builder: (_) => WebSocketMapScreen());
            }
            // Manejar otras rutas si es necesario
            return null;
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute(builder: (_) => LoginScreen());
          },
        );
      },
    );
  }
}
