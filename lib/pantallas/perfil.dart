import 'package:flutter/material.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
            backgroundColor: Colors.grey[300],
          ),
          SizedBox(height: 20),
          Text(
            'Usuario',
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 10),
          Text('Configuración del perfil'),
        ],
      ),
    );
  }
}