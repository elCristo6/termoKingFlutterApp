// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context,
          listen: false); // Obtén authProvider
      final token = await authService.loginUser(
          userId, password, authProvider); // Pasa authProvider como argumento

      if (token != null) {
        await authProvider.loadToken();
        Navigator.pushReplacementNamed(context, '/map');
      } else {
        setState(() {
          _errorMessage = 'Credenciales inválidas o error en el servidor.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error. Por favor, intenta de nuevo.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildLoginForm(double screenHeight) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200.0,
            height: 200.0,
            child: Image.asset('assets/thermoLogo.png'),
          ),
          SizedBox(height: screenHeight * 0.05),
          TextFormField(
            controller: _userIdController,
            decoration: InputDecoration(
              labelText: 'User ID',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, ingresa tu User ID.';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, ingresa tu contraseña.';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _login,
                    child: Text(
                      'Iniciar Sesión',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 5,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              width: screenWidth,
              height: screenHeight -
                  mediaQuery.padding.top -
                  mediaQuery.padding.bottom,
              child: _buildLoginForm(screenHeight),
            ),
          ),
        ),
      ),
    );
  }
}
