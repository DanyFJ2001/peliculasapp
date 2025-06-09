import 'package:appcine/screens/loginscreen.dart';
import 'package:appcine/screens/registroscreen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(AppCine());
}

class AppCine extends StatelessWidget {
  const AppCine({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PantallaBienvenida(),
    );
  }
}

class PantallaBienvenida extends StatelessWidget {
  const PantallaBienvenida({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Bienvenido!',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Container(
              width: 150,
              height: 150,
              child: Image.asset(
                'assets/imagenes/12.jpg',
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 30),
            btnIniciarSesion(context),
            SizedBox(height: 20),
            btnRegistro(context),
          ],
        ),
      ),
    );
  }
}

Widget btnIniciarSesion(context) {
  return FilledButton.tonal(
      onPressed: () => Navigator.push(context, 
          MaterialPageRoute(builder: (context) => LoginScreen())),
      child: Text('Iniciar Sesión'));
}

Widget btnRegistro(context) {
  return FilledButton.tonal(
      onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (context) => RegistroScreen())),
      child: Text('Registro'));
}